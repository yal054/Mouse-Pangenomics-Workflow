import argparse
import pandas as pd
from concurrent.futures import ProcessPoolExecutor

STRICT_FOUNDER_COLUMNS = [
    '129S1_SvImJ',
    'A_J',
    'CAST_EiJ_T2T_Keane',
    'C57BL_6_T2T_Yu',
    'NOD_ShiLtJ',
    'NZO_HlLtJ',
    'PWK_PhJ',
    'WSB_EiJ'
]

FOUNDER_SUPPORT_GROUPS = {
    '129S1_SvImJ': ['129S1_SvImJ'],
    'A_J': ['A_J'],
    'CAST_EiJ': ['CAST_EiJ', 'CAST_EiJ_T2T_Keane'],
    'C57BL_6J': ['C57BL_6J_T2T_Keane', 'C57BL_6_T2T_Yu', "GRCm39"],
    'NOD_ShiLtJ': ['NOD_ShiLtJ'],
    'NZO_HlLtJ': ['NZO_HlLtJ'],
    'PWK_PhJ': ['PWK_PhJ'],
    'WSB_EiJ': ['WSB_EiJ']
}


def load_variant_data(input_file):
    print(f"Loading variant data from {input_file}...")
    df = pd.read_csv(input_file, sep="\t", dtype=str, low_memory=False)
    df.columns = df.columns.str.replace(r':GT$', '', regex=True)
    print(f"Loaded {df.shape[0]} variants and {df.shape[1] - 2} samples.")
    return df


def get_available_founder_support_groups(columns):
    available_groups = {}
    for founder_name, aliases in FOUNDER_SUPPORT_GROUPS.items():
        present_aliases = [alias for alias in aliases if alias in columns]
        if present_aliases:
            available_groups[founder_name] = present_aliases
    return available_groups


def get_available_strict_founders(columns):
    return [col for col in STRICT_FOUNDER_COLUMNS if col in columns]


def collect_group_genotypes(row, founder_groups):
    grouped_genotypes = {}
    for founder_name, columns in founder_groups.items():
        grouped_genotypes[founder_name] = [
            row[col] for col in columns if row[col] not in (None, '')
        ]
    return grouped_genotypes


WORKER_FOUNDER_SUPPORT_GROUPS = None
WORKER_STRICT_FOUNDERS = None
WORKER_RIS = None


def init_worker(founder_support_groups, strict_founders, RIs):
    global WORKER_FOUNDER_SUPPORT_GROUPS, WORKER_STRICT_FOUNDERS, WORKER_RIS
    WORKER_FOUNDER_SUPPORT_GROUPS = founder_support_groups
    WORKER_STRICT_FOUNDERS = strict_founders
    WORKER_RIS = RIs


def process_row(row):
    founder_support_groups = WORKER_FOUNDER_SUPPORT_GROUPS
    strict_founders = WORKER_STRICT_FOUNDERS
    RIs = WORKER_RIS

    total_founders = len(founder_support_groups)
    total_strict_founders = len(strict_founders)
    total_RIs = len(RIs)

    chrom, pos = row['CHROM'], row['POS']

    all_sample_cols = [c for cols in founder_support_groups.values() for c in cols] + RIs
    has_missing = any(row[c] == '.' for c in all_sample_cols)

    founder_group_genotypes = collect_group_genotypes(row, founder_support_groups)
    founder_support_genotypes = [
        gt for group_genotypes in founder_group_genotypes.values() for gt in group_genotypes
    ]
    strict_founder_genotypes = [row[col] for col in strict_founders if row[col] not in (None, '')]
    RI_genotypes = [row[col] for col in RIs if row[col] not in (None, '')]

    raw_gt_set = set(founder_support_genotypes + RI_genotypes)
    if has_missing:
        raw_gt_set.add('.')
    unique_genotypes = sorted(raw_gt_set)

    founder_counts = []
    founder_counts_strict = []
    RI_counts = []
    founder_fractions = []
    founder_fractions_strict = []
    RI_fractions = []
    presence = []
    presence_strict = []

    for gt in unique_genotypes:
        founder_count = sum(
            gt in group_genotypes for group_genotypes in founder_group_genotypes.values()
        )
        strict_founder_count = strict_founder_genotypes.count(gt)
        RI_count = RI_genotypes.count(gt)

        if RI_count > 0:
            presence_label = "both" if founder_count > 0 else "RI"
            presence_label_strict = "both" if strict_founder_count > 0 else "RI"
        elif founder_count > 0:
            presence_label = "founder"
            presence_label_strict = "founder" if strict_founder_count > 0 else "unknown"
        else:
            presence_label = "unknown"
            presence_label_strict = "unknown"

        founder_counts.append(founder_count)
        founder_counts_strict.append(strict_founder_count)
        RI_counts.append(RI_count)
        founder_fractions.append(round(founder_count / total_founders, 4) if total_founders > 0 else 0)
        founder_fractions_strict.append(round(strict_founder_count / total_strict_founders, 4) if total_strict_founders > 0 else 0)
        RI_fractions.append(round(RI_count / total_RIs, 4) if total_RIs > 0 else 0)
        presence.append(presence_label)
        presence_strict.append(presence_label_strict)

    total_unique = len(unique_genotypes)

    if has_missing:
        founder_only = 'NA'
        both = 'NA'
        RI_only = 'NA'
        founder_only_fraction = 'NA'
        both_fraction = 'NA'
        RI_only_fraction = 'NA'

        founder_strain_only = 'NA'
        founder_strain_both = 'NA'
        founder_strain_only_fraction = 'NA'
        founder_strain_both_fraction = 'NA'

        founder_strain_only_strict = 'NA'
        founder_strain_both_strict = 'NA'
        founder_strain_only_fraction_strict = 'NA'
        founder_strain_both_fraction_strict = 'NA'
    else:
        ri_genotype_set = set(RI_genotypes)

        founder_only = sum(
            1 for gt in unique_genotypes
            if gt in founder_support_genotypes and gt not in RI_genotypes
        )
        both = sum(
            1 for gt in unique_genotypes
            if gt in RI_genotypes and gt in founder_support_genotypes
        )
        RI_only = sum(
            1 for gt in unique_genotypes
            if gt in RI_genotypes and gt not in founder_support_genotypes
        )
        founder_only_fraction = round(founder_only / total_unique, 4) if total_unique > 0 else 0
        both_fraction = round(both / total_unique, 4) if total_unique > 0 else 0
        RI_only_fraction = round(RI_only / total_unique, 4) if total_unique > 0 else 0

        callable_founder_groups = 0
        founder_strain_only = 0
        founder_strain_both = 0
        for group_genotypes in founder_group_genotypes.values():
            group_genotype_set = set(group_genotypes)
            if len(group_genotype_set) == 0:
                continue
            callable_founder_groups += 1
            if ri_genotype_set.isdisjoint(group_genotype_set):
                founder_strain_only += 1
            else:
                founder_strain_both += 1

        callable_strict_founders = 0
        founder_strain_only_strict = 0
        founder_strain_both_strict = 0
        for col in strict_founders:
            gt = row[col]
            if gt in (None, ''):
                continue
            callable_strict_founders += 1
            if gt in ri_genotype_set:
                founder_strain_both_strict += 1
            else:
                founder_strain_only_strict += 1

        founder_strain_only_fraction = round(founder_strain_only / callable_founder_groups, 4) if callable_founder_groups > 0 else 0
        founder_strain_both_fraction = round(founder_strain_both / callable_founder_groups, 4) if callable_founder_groups > 0 else 0
        founder_strain_only_fraction_strict = round(founder_strain_only_strict / callable_strict_founders, 4) if callable_strict_founders > 0 else 0
        founder_strain_both_fraction_strict = round(founder_strain_both_strict / callable_strict_founders, 4) if callable_strict_founders > 0 else 0

    return {
        'CHROM': chrom,
        'POS': pos,
        'Unique_Genotypes': ','.join(unique_genotypes),
        'Founder_Count': ','.join(map(str, founder_counts)),
        'Founder_Count_Strict': ','.join(map(str, founder_counts_strict)),
        'RI_Count': ','.join(map(str, RI_counts)),
        'Founder_Fraction': ','.join(map(str, founder_fractions)),
        'Founder_Fraction_Strict': ','.join(map(str, founder_fractions_strict)),
        'RI_Fraction': ','.join(map(str, RI_fractions)),
        'Presence': ','.join(presence),
        'Presence_Strict': ','.join(presence_strict),
        'Total_Unique_Genotypes': total_unique,
        'Founder_Only': founder_only,
        'Both': both,
        'RI_Only': RI_only,
        'Founder_Only_Fraction': founder_only_fraction,
        'Both_Fraction': both_fraction,
        'RI_Only_Fraction': RI_only_fraction,
        'Founder_Strain_Only': founder_strain_only,
        'Founder_Strain_Both': founder_strain_both,
        'Founder_Strain_Only_Fraction': founder_strain_only_fraction,
        'Founder_Strain_Both_Fraction': founder_strain_both_fraction,
        'Founder_Strain_Only_Strict': founder_strain_only_strict,
        'Founder_Strain_Both_Strict': founder_strain_both_strict,
        'Founder_Strain_Only_Fraction_Strict': founder_strain_only_fraction_strict,
        'Founder_Strain_Both_Fraction_Strict': founder_strain_both_fraction_strict
    }


def calculate_unique_genotypes(df, founder_support_groups, strict_founders, RIs, threads=1):
    print("Calculating unique genotypes and counts per position...")

    rows = df.to_dict(orient="records")

    if threads > 1:
        chunksize = max(1, len(rows) // (threads * 4))
        with ProcessPoolExecutor(
            max_workers=threads,
            initializer=init_worker,
            initargs=(founder_support_groups, strict_founders, RIs)
        ) as executor:
            results = list(executor.map(process_row, rows, chunksize=chunksize))
    else:
        init_worker(founder_support_groups, strict_founders, RIs)
        results = [process_row(row) for row in rows]

    print("Calculation complete.")
    return pd.DataFrame(results)


def save_results(results_df, output_file):
    print(f"Saving results to {output_file}...")
    results_df.to_csv(output_file, sep='\t', index=False)
    print("Results saved successfully.")


def main():
    parser = argparse.ArgumentParser(description="Analyze founder and RI genotype coverage per position.")
    parser.add_argument("input_file", type=str, help="Input file containing variant genotype data.")
    parser.add_argument("--output_file", type=str, default="genotype_summary.csv",
                        help="Output file to save the results (default: genotype_summary.csv).")
    parser.add_argument("--threads", type=int, default=1,
                        help="Number of threads to use (default: 1).")
    args = parser.parse_args()

    df_sample = pd.read_csv(args.input_file, sep="\t", nrows=1)
    df_sample.columns = df_sample.columns.str.replace(r':GT$', '', regex=True)

    founder_groups = get_available_founder_support_groups(df_sample.columns)
    strict_founders = get_available_strict_founders(df_sample.columns)
    founder_columns = sorted({col for cols in founder_groups.values() for col in cols})
    RIs = [col for col in df_sample.columns if col not in ['CHROM', 'POS'] + founder_columns]

    print("Using founder support groups for RI comparison:")
    for founder_name, columns in founder_groups.items():
        print(f"  {founder_name}: {', '.join(columns)}")
    print("Using strict founder columns for founder-only calls:")
    for founder_name in strict_founders:
        print(f"  {founder_name}")
    print(f"Using {args.threads} thread(s).")

    df = load_variant_data(args.input_file)
    results_df = calculate_unique_genotypes(df, founder_groups, strict_founders, RIs, threads=args.threads)
    save_results(results_df, args.output_file)


if __name__ == "__main__":
    main()