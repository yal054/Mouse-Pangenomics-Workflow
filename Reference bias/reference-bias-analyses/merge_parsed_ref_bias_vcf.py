#!/usr/bin/env python3
"""
merge_parsed_ref_bias_vcf.py

This script merges multiple parsed ref‐bias VCF files by "chrom/start/end".
Each input must contain:
    chrom, start, end, allele_fraction, filtered_DP

For each file:
  - allele_fraction → renamed to <basename>
  - filtered_DP     → renamed to <basename>.filtered_DP

After merging all samples:
  1. Compute diff_1_minus_2, diff_1_minus_3, … on the allele_fraction columns.
  2. For each sample, run a one‐sided binomial test:
        k = round( allele_fraction × DP )
        N = DP
        p = sum_{i=k..N} [C(N,i) × (0.5)^N]
     and store that in <basename>.pvalue.
  3. Replace any NaN with the string "NA" and write everything as a TSV.

Usage:
    python merge_parsed_ref_bias_vcf.py sample1.tsv sample2.tsv … -o merged.tsv
"""

import argparse
import os
import pandas as pd
import math


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Merge parsed REF‐bias VCF TSVs, keep DP, compute allele_fraction differences, "
                    "and run a one‐sided binomial test per sample."
    )
    parser.add_argument(
        "files",
        nargs="+",
        help="Paths to parsed REF‐bias files (TSV). Each must have columns: "
             "'chrom','start','end','allele_fraction','filtered_DP'."
    )
    parser.add_argument(
        "-o", "--output",
        required=True,
        help="Path to the merged TSV output."
    )
    return parser.parse_args()


def merge_files(file_paths):
    """
    For each input TSV:
      - Read with pandas
      - Verify required columns
      - Keep only [chrom, start, end, allele_fraction, filtered_DP]
      - Rename allele_fraction → <basename>
               filtered_DP     → <basename>.filtered_DP
      - Outer‐merge on ['chrom','start','end'] across all files
    """
    merged_df = None

    for file_path in file_paths:
        try:
            df = pd.read_csv(file_path, sep="\t")
        except Exception as e:
            raise RuntimeError(f"Error reading '{file_path}': {e}")

        required_cols = {"chrom", "start", "end", "allele_fraction", "filtered_DP"}
        if not required_cols.issubset(df.columns):
            missing = required_cols - set(df.columns)
            raise RuntimeError(f"File '{file_path}' is missing required column(s): {', '.join(missing)}")

        # Keep only the needed columns
        df = df[["chrom", "start", "end", "allele_fraction", "filtered_DP"]]

        # Rename:
        basename = os.path.basename(file_path)
        df = df.rename(
            columns={
                "allele_fraction": basename,
                "filtered_DP": f"{basename}.filtered_DP"
            }
        )

        if merged_df is None:
            merged_df = df
        else:
            merged_df = pd.merge(merged_df, df, on=["chrom", "start", "end"], how="outer")

    return merged_df


def compute_fraction_differences(merged_df):
    """
    Identify all allele_fraction columns (those not ending with '.filtered_DP'
    and not in ['chrom','start','end']), then:
      diff_1_minus_2 = col1 - col2
      diff_1_minus_3 = col1 - col3
      etc.
    Adds these difference columns in‐place.
    """
    all_cols = list(merged_df.columns)
    key_cols = ["chrom", "start", "end"]
    # allele_fraction columns are those not in key_cols and not ending with ".filtered_DP"
    allele_cols = [c for c in all_cols if c not in key_cols and not c.endswith(".filtered_DP")]

    if len(allele_cols) < 2:
        print("Warning: fewer than two allele_fraction columns; skipping diff computation.")
        return merged_df

    ref_col = allele_cols[0]  # use first as reference
    for idx, other_col in enumerate(allele_cols[1:], start=2):
        diff_name = f"diff_1_minus_{idx}"
        merged_df[diff_name] = merged_df[ref_col] - merged_df[other_col]

    return merged_df


def one_sided_binomial_pval(k, N):
    """
    Compute the one‐sided binomial p‐value for observing ≥ k REF‐reads
    out of N, under p=0.5.  That is:
        p = sum_{i=k..N} [C(N,i) * (0.5)^N]
    """
    if N < 0 or k < 0 or k > N:
        return float("nan")

    # If k = 0, p = 1, because P(X ≥ 0) = 1
    if k == 0:
        return 1.0

    # Sum combinations; avoid recomputing (0.5)^N each time
    half_pow = 0.5**N
    total = 0.0
    for i in range(k, N + 1):
        total += math.comb(N, i)
    return total * half_pow


def add_binomial_pvalues(merged_df, sample_basenames):
    """
    For each sample basename in sample_basenames:
      - allele_fraction column = basename
      - DP column              = basename + ".filtered_DP"
      Compute:
        k = round( allele_fraction * DP )
        N = DP
        pvalue = one_sided_binomial_pval(k, N)
      Store p‐value in column: <basename>.pvalue
    """
    for basename in sample_basenames:
        frac_col = basename
        dp_col   = f"{basename}.filtered_DP"
        pval_col = f"{basename}.pvalue"

        def compute_row_pval(row):
            af = row.get(frac_col)
            dp = row.get(dp_col)
            # If either is missing or not numeric, return NaN
            if pd.isna(af) or pd.isna(dp):
                return float("nan")
            try:
                dp_int = int(dp)
            except ValueError:
                return float("nan")

            # Compute k = round(af * dp)
            k = int(round(af * dp_int))
            # Bound k to [0..dp_int]
            k = max(0, min(k, dp_int))
            return one_sided_binomial_pval(k, dp_int)

        merged_df[pval_col] = merged_df.apply(compute_row_pval, axis=1)

    return merged_df


def main():
    args = parse_arguments()

    # 1) Merge and rename columns
    merged_df = merge_files(args.files)

    # 2) Compute diff_1_minus_N on allele_fraction
    merged_df = compute_fraction_differences(merged_df)

    # 3) Identify sample basenames (the allele_fraction columns)
    all_cols  = list(merged_df.columns)
    key_cols  = {"chrom", "start", "end"}
    # allele_fraction columns = those not in key_cols and not ending with ".filtered_DP"
    sample_basenames = [c for c in all_cols
                        if c not in key_cols and not c.endswith(".filtered_DP")
                        and not c.startswith("diff_") and not c.endswith(".pvalue")]

    # 4) Add per‐sample binomial p‐values
    merged_df = add_binomial_pvalues(merged_df, sample_basenames)

    # 5) Replace any remaining NaN with "NA"
    merged_df = merged_df.where(pd.notnull(merged_df), "NA")

    # 6) Write out as TSV
    try:
        merged_df.to_csv(args.output, sep="\t", index=False)
        print(f"Successfully wrote merged output (with DP & p‐values) to: {args.output}")
    except Exception as e:
        raise RuntimeError(f"Error writing '{args.output}': {e}")


if __name__ == "__main__":
    main()
