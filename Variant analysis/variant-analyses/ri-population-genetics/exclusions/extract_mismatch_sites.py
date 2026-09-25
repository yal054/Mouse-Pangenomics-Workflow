#!/usr/bin/env python3
"""
extract_mismatch_sites.py

Single-pass over a multi-sample vg-deconstruct VCF.  For each variant site,
for every sample covered by its mosaic haplotype (.hap) file, classifies the
outcome against the expected founder genotype (Match / Mismatch / Missing).

Emits one output row PER VCF SITE that has at least one sample inside a
mosaic interval.  Counts are pooled across all samples.

Additional per-site features:
  var_type          : SNP | INS | DEL | MNP | MULTIALLELIC
  n_founders_nonref : how many of the 8 founders carry any non-ref allele

Usage
-----
python3 extract_mismatch_sites.py \\
    --vcf  /path/to/founder.plus_allCC.deconstruct.mm10.noprefix.vcf \\
    --samples  samples.tsv \\
    --out  mismatch_sites.tsv

samples.tsv: two-column TSV (no header)
    sample_name   /full/path/to/CC001.hap
    ...

Output columns (TSV with header)
    chrom  start  end  ref  alt_str  var_type  n_founders_nonref
    n_inside_mosaic  n_mismatch  n_match  n_missing_sample
    n_missing_founder  n_missing_both
"""

import argparse
import gzip
import sys
from bisect import bisect_right
from collections import defaultdict
from typing import Dict, List, Optional, Tuple, Iterable


# ── Founder letter → VCF sample name mapping ─────────────────────────────────
FOUNDER_LETTER_TO_VCF_SAMPLE = {
    "A": "A_J",
    "B": "C57BL_6_T2T_Yu",
    "C": "129S1_SvImJ",
    "D": "NOD_ShiLtJ",
    "E": "NZO_HlLtJ",
    "F": "CAST_EiJ_T2T_Keane",
    "G": "PWK_PhJ",
    "H": "WSB_EiJ",
}


# ── Utilities (shared with score_mosaic_concordance.py) ────────────────────

def open_text_maybe_gzip(path: str):
    return gzip.open(path, "rt") if path.endswith(".gz") else open(path, "r")


class IntervalMap:
    def __init__(self, intervals: List[Tuple[int, int, str]]):
        intervals.sort(key=lambda x: x[0])
        self.starts = [s for s, _, _ in intervals]
        self.ends   = [e for _, e, _ in intervals]
        self.labels = [lab for _, _, lab in intervals]

    def query(self, pos: int) -> Optional[str]:
        if not self.starts:
            return None
        i = bisect_right(self.starts, pos) - 1
        if i < 0:
            return None
        return self.labels[i] if pos <= self.ends[i] else None


def parse_hapl(path: str) -> Dict[str, Tuple[IntervalMap, IntervalMap]]:
    chrom_to_haps: Dict[str, List[IntervalMap]] = defaultdict(list)

    def parse_chr_line(raw_line: str) -> Tuple[str, IntervalMap]:
        toks = raw_line.rstrip("\n").split(",")
        chrom = toks[0]
        intervals: List[Tuple[int, int, str]] = []
        i = 2
        while i + 2 < len(toks):
            founder = toks[i].strip()
            start_s = toks[i + 1].strip().strip('"')
            end_s   = toks[i + 2].strip().strip('"')
            if not founder or not start_s or not end_s:
                break
            try:
                start = int(start_s)
                end   = int(end_s)
            except ValueError:
                break
            intervals.append((start, end, founder))
            i += 3
        return chrom, IntervalMap(intervals)

    with open_text_maybe_gzip(path) as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            if line.startswith(("set,", "title,", "grid,")):
                continue
            if line.startswith("gap"):
                continue
            if line.startswith("chr"):
                chrom, imap = parse_chr_line(raw)
                chrom_to_haps[chrom].append(imap)

    out: Dict[str, Tuple[IntervalMap, IntervalMap]] = {}
    for chrom, haps in chrom_to_haps.items():
        if len(haps) >= 2:
            out[chrom] = (haps[0], haps[1])
        elif len(haps) == 1:
            out[chrom] = (haps[0], IntervalMap([]))
        else:
            out[chrom] = (IntervalMap([]), IntervalMap([]))
    return out


def parse_gt_field(gt: str) -> Optional[Tuple[int, int]]:
    gt = gt.strip()
    if gt in (".", "./.", ".|."):
        return None
    if "|" in gt:
        parts = gt.split("|")
    elif "/" in gt:
        parts = gt.split("/")
    else:
        try:
            a = int(gt)
        except ValueError:
            return None
        return (a, a)
    if len(parts) != 2:
        return None
    if parts[0] == "." or parts[1] == ".":
        return None
    try:
        return (int(parts[0]), int(parts[1]))
    except ValueError:
        return None


def parse_founder_single_allele(gt: str) -> Optional[int]:
    ab = parse_gt_field(gt)
    if ab is None:
        return None
    a, b = ab
    if a != b:
        return None
    return a


def iter_vcf_records(vcf_path: str) -> Iterable[Tuple[List[str], List[str]]]:
    header_samples: Optional[List[str]] = None
    with open_text_maybe_gzip(vcf_path) as f:
        for raw in f:
            if raw.startswith("##"):
                continue
            if raw.startswith("#CHROM"):
                cols = raw.rstrip("\n").split("\t")
                header_samples = cols[9:]
                continue
            if raw.startswith("#"):
                continue
            if header_samples is None:
                raise RuntimeError("VCF header not found before records.")
            yield header_samples, raw.rstrip("\n").split("\t")


def expected_pair_label(f1: str, f2: str) -> str:
    a, b = (f1, f2) if f1 <= f2 else (f2, f1)
    return f"{a}/{b}"


# ── New helpers ───────────────────────────────────────────────────────────────

def classify_variant(ref: str, alts: List[str]) -> str:
    if len(alts) > 1:
        return "MULTIALLELIC"
    alt = alts[0]
    lr, la = len(ref), len(alt)
    if lr == 1 and la == 1:
        return "SNP"
    if lr == la:
        return "MNP"
    if lr < la:
        return "INS"
    return "DEL"


def count_founders_nonref(
    fields: List[str],
    founder_col_idx_by_letter: Dict[str, int],
    gt_i: Optional[int],
) -> int:
    n = 0
    for _letter, col in founder_col_idx_by_letter.items():
        sf = fields[col]
        if gt_i is None:
            gt_str = "."
        elif ":" in sf:
            parts = sf.split(":")
            gt_str = parts[gt_i] if gt_i < len(parts) else "."
        else:
            gt_str = sf if gt_i == 0 else "."
        ab = parse_gt_field(gt_str)
        if ab is not None and any(a != 0 for a in ab):
            n += 1
    return n


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--vcf",     required=True, help="Input VCF (plain or gzipped)")
    ap.add_argument("--samples", required=True, help="2-col TSV: sample_name  hapl_path")
    ap.add_argument("--out",     required=True, help="Output TSV path")
    args = ap.parse_args()

    # Load sample → hapl mapping
    sample_hapl_paths: List[Tuple[str, str]] = []
    with open(args.samples) as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                sys.exit(f"ERROR: expected 2 tab-separated columns, got: {line!r}")
            sample_hapl_paths.append((parts[0], parts[1]))

    sys.stderr.write(f"Loading {len(sample_hapl_paths)} hapl files …\n")
    sample_chrom_haps = []
    for sample_name, hapl_path in sample_hapl_paths:
        chrom_haps = parse_hapl(hapl_path)
        sample_chrom_haps.append((sample_name, chrom_haps))
    sys.stderr.write("Hapl files loaded.\n")

    # First VCF pass: build column index maps
    founder_col_idx_by_letter: Dict[str, int] = {}
    sample_col_idx_by_name: Dict[str, int] = {}

    initialized = False
    n_records = 0

    with open(args.out, "w") as out_fh:
        out_fh.write(
            "chrom\tstart\tend\tref\talt_str\tvar_type\tn_founders_nonref"
            "\tn_inside_mosaic\tn_mismatch\tn_match"
            "\tn_missing_sample\tn_missing_founder\tn_missing_both\n"
        )

        for hdr_samples, fields in iter_vcf_records(args.vcf):

            # ── One-time initialisation from the first record ─────────────
            if not initialized:
                initialized = True

                missing_founders = []
                for letter, vcf_name in FOUNDER_LETTER_TO_VCF_SAMPLE.items():
                    if vcf_name not in hdr_samples:
                        missing_founders.append((letter, vcf_name))
                    else:
                        founder_col_idx_by_letter[letter] = 9 + hdr_samples.index(vcf_name)
                if missing_founders:
                    msgs = ["ERROR: missing founder columns in VCF:"]
                    for lt, nm in missing_founders:
                        msgs.append(f"  {lt} -> {nm}")
                    sys.exit("\n".join(msgs))

                missing_samples = []
                for sample_name, _ in sample_hapl_paths:
                    if sample_name not in hdr_samples:
                        missing_samples.append(sample_name)
                    else:
                        sample_col_idx_by_name[sample_name] = 9 + hdr_samples.index(sample_name)
                if missing_samples:
                    sys.exit(f"ERROR: samples not in VCF header: {missing_samples}")

                sys.stderr.write("Founder columns found. Starting site iteration …\n")

            # ── Per-record processing ─────────────────────────────────────
            chrom   = fields[0]
            pos     = int(fields[1])
            ref     = fields[3]
            alt_str = fields[4]
            alts    = alt_str.split(",")

            fmt_keys = fields[8].split(":")
            try:
                gt_i = fmt_keys.index("GT")
            except ValueError:
                gt_i = None

            def get_gt_str(col_idx: int) -> str:
                sf = fields[col_idx]
                if gt_i is None:
                    return "."
                if ":" in sf:
                    parts = sf.split(":")
                    return parts[gt_i] if gt_i < len(parts) else "."
                return sf if gt_i == 0 else "."

            # Variant features
            var_type         = classify_variant(ref, alts)
            n_founders_nonref = count_founders_nonref(
                fields, founder_col_idx_by_letter, gt_i
            )

            # BED coordinates (0-based)
            start = pos - 1
            end   = pos - 1 + len(ref)

            # Per-sample scoring
            n_inside = n_mismatch = n_match = 0
            n_miss_samp = n_miss_found = n_miss_both = 0

            for sample_name, chrom_haps in sample_chrom_haps:
                hap_maps = chrom_haps.get(chrom)
                if hap_maps is None:
                    continue
                hap1_map, hap2_map = hap_maps
                f1 = hap1_map.query(pos)
                f2 = hap2_map.query(pos)
                if f1 is None or f2 is None:
                    continue  # outside mosaic for this sample

                n_inside += 1

                sample_gt = parse_gt_field(get_gt_str(sample_col_idx_by_name[sample_name]))
                sample_missing = sample_gt is None

                f1_allele = parse_founder_single_allele(
                    get_gt_str(founder_col_idx_by_letter[f1])
                )
                f2_allele = parse_founder_single_allele(
                    get_gt_str(founder_col_idx_by_letter[f2])
                )
                founder_missing = (f1_allele is None or f2_allele is None)

                if sample_missing and founder_missing:
                    n_miss_both += 1
                elif sample_missing:
                    n_miss_samp += 1
                elif founder_missing:
                    n_miss_found += 1
                else:
                    a, b = sample_gt
                    exp = sorted([f1_allele, f2_allele])
                    obs = sorted([a, b])
                    if obs == exp:
                        n_match += 1
                    else:
                        n_mismatch += 1

            if n_inside == 0:
                continue  # no sample had mosaic coverage here

            out_fh.write(
                f"{chrom}\t{start}\t{end}\t{ref}\t{alt_str}\t{var_type}"
                f"\t{n_founders_nonref}"
                f"\t{n_inside}\t{n_mismatch}\t{n_match}"
                f"\t{n_miss_samp}\t{n_miss_found}\t{n_miss_both}\n"
            )

            n_records += 1
            if n_records % 1_000_000 == 0:
                sys.stderr.write(f"  … {n_records:,} records processed\n")

    sys.stderr.write(f"Done. {n_records:,} sites written to {args.out}\n")


if __name__ == "__main__":
    main()
