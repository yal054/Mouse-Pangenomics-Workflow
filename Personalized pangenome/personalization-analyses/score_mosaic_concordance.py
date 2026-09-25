#!/usr/bin/env python3
import argparse
import gzip
import sys
from bisect import bisect_right
from collections import defaultdict
from typing import Dict, List, Optional, Tuple, Iterable


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


def open_text_maybe_gzip(path: str):
    return gzip.open(path, "rt") if path.endswith(".gz") else open(path, "r")


class IntervalMap:
    def __init__(self, intervals: List[Tuple[int, int, str]]):
        intervals.sort(key=lambda x: x[0])
        self.starts = [s for s, _, _ in intervals]
        self.ends = [e for _, e, _ in intervals]
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
        i = 2  # toks[1] is empty in example
        while i + 2 < len(toks):
            founder = toks[i].strip()
            start_s = toks[i + 1].strip().strip('"')
            end_s = toks[i + 2].strip().strip('"')
            if not founder or not start_s or not end_s:
                break
            try:
                start = int(start_s)
                end = int(end_s)
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
        # haploid-like encoding
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--vcf", required=True)
    ap.add_argument("--sample", required=True)
    ap.add_argument("--hapl", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    chrom_haps = parse_hapl(args.hapl)

    # counts[chrom][expected_class][outcome] = n
    counts = defaultdict(lambda: defaultdict(lambda: defaultdict(int)))

    header_samples = None
    sample_col_idx = None
    founder_col_idx_by_letter = {}

    seen_any = False

    for hdr_samples, fields in iter_vcf_records(args.vcf):
        if not seen_any:
            seen_any = True
            header_samples = hdr_samples

            if args.sample not in header_samples:
                raise SystemExit(f"ERROR: sample not found in VCF header: {args.sample}\n")
            sample_col_idx = 9 + header_samples.index(args.sample)

            missing = []
            for letter, vcf_name in FOUNDER_LETTER_TO_VCF_SAMPLE.items():
                if vcf_name not in header_samples:
                    missing.append((letter, vcf_name))
                else:
                    founder_col_idx_by_letter[letter] = 9 + header_samples.index(vcf_name)

            if missing:
                msg = ["ERROR: missing founder columns in VCF header:"]
                for letter, vcf_name in missing:
                    msg.append(f"  {letter} -> {vcf_name}")
                raise SystemExit("\n".join(msg) + "\n")

            sys.stderr.write("Founder mapping used:\n")
            for k in sorted(FOUNDER_LETTER_TO_VCF_SAMPLE.keys()):
                sys.stderr.write(f"  {k} -> {FOUNDER_LETTER_TO_VCF_SAMPLE[k]}\n")
            sys.stderr.write(f"Scoring sample: {args.sample}\n")

        chrom = fields[0]
        pos = int(fields[1])

        fmt_keys = fields[8].split(":")
        try:
            gt_i = fmt_keys.index("GT")
        except ValueError:
            gt_i = None

        def get_gt_string(col_idx: int) -> str:
            sf = fields[col_idx]
            if gt_i is None:
                return "."
            if ":" in sf:
                parts = sf.split(":")
                return parts[gt_i] if gt_i < len(parts) else "."
            # FORMAT only GT
            return sf if gt_i == 0 else "."

        # sample GT
        sample_gt = parse_gt_field(get_gt_string(sample_col_idx))
        sample_missing = sample_gt is None

        # mosaic lookup, strict: inside only if both hap labels exist
        hap_maps = chrom_haps.get(chrom, None)
        if hap_maps is None:
            f1 = None
            f2 = None
        else:
            hap1_map, hap2_map = hap_maps
            f1 = hap1_map.query(pos)
            f2 = hap2_map.query(pos)

        inside_mosaic = (f1 is not None and f2 is not None)

        if not inside_mosaic:
            # Outside mosaic: expected_class is the sample genotype itself (phase ignored)
            if sample_missing:
                expected_class = "./."
                outcome = "Missing_Sample"
            else:
                a, b = sample_gt
                x, y = (a, b) if a <= b else (b, a)
                expected_class = f"{x}/{y}"
                outcome = "Outside_Mosaic"
            counts[chrom][expected_class][outcome] += 1
            continue

        # Inside mosaic: expected_class is the founder-pair label (phase ignored)
        expected_class = expected_pair_label(f1, f2)

        # founders
        f1_idx = founder_col_idx_by_letter[f1]
        f2_idx = founder_col_idx_by_letter[f2]
        allele1 = parse_founder_single_allele(get_gt_string(f1_idx))
        allele2 = parse_founder_single_allele(get_gt_string(f2_idx))

        founder_missing = (allele1 is None or allele2 is None)

        if sample_missing and founder_missing:
            outcome = "Missing_Both"
        elif sample_missing:
            outcome = "Missing_Sample"
        elif founder_missing:
            outcome = "Missing_Founder"
        else:
            a, b = sample_gt
            # expected diploid allele multiset
            exp = sorted([allele1, allele2])
            obs = sorted([a, b])
            outcome = "Match" if obs == exp else "Mismatch"

        counts[chrom][expected_class][outcome] += 1

    # write long output
    with open(args.out, "w") as out:
        out.write("chrom\texpected_class\toutcome\tn_sites\n")
        for chrom in sorted(counts.keys()):
            for expected_class in sorted(counts[chrom].keys()):
                for outcome in sorted(counts[chrom][expected_class].keys()):
                    out.write(f"{chrom}\t{expected_class}\t{outcome}\t{counts[chrom][expected_class][outcome]}\n")

    sys.stderr.write(f"Wrote: {args.out}\n")


if __name__ == "__main__":
    main()