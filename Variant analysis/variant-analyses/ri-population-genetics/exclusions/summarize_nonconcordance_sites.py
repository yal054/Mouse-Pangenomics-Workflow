#!/usr/bin/env python3
import argparse
import gzip
import os
import sys
from collections import defaultdict
from itertools import permutations


FOUNDERS = ["A", "B", "C", "D", "E", "F", "G", "H"]


def open_text_maybe_gzip(path):
    if path.endswith(".gz"):
        return gzip.open(path, "rt")
    return open(path, "r")


def list_bed_files(indir):
    files = []
    for name in sorted(os.listdir(indir)):
        path = os.path.join(indir, name)
        if not os.path.isfile(path):
            continue
        if name.endswith(".bed") or name.endswith(".bed.gz"):
            files.append(path)
    return files


def parse_gt_field(gt):
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


def iter_nonconcordance_records(path):
    header = None
    col_idx = None

    with open_text_maybe_gzip(path) as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            if line.startswith("#"):
                continue

            fields = line.split("\t")

            if header is None:
                header = fields
                col_idx = {name: i for i, name in enumerate(header)}

                required = [
                    "chrom",
                    "start",
                    "end",
                    "outcome",
                    "sample_gt",
                    "founder1",
                    "founder2",
                    "founder1_allele",
                    "founder2_allele",
                ]

                missing = [x for x in required if x not in col_idx]
                if missing:
                    raise SystemExit(
                        f"ERROR: {path} is missing required columns: {', '.join(missing)}"
                    )
                continue

            yield {
                "chrom": fields[col_idx["chrom"]],
                "start": int(fields[col_idx["start"]]),
                "end": int(fields[col_idx["end"]]),
                "outcome": fields[col_idx["outcome"]],
                "sample_gt": fields[col_idx["sample_gt"]],
                "founder1": fields[col_idx["founder1"]],
                "founder2": fields[col_idx["founder2"]],
                "founder1_allele": fields[col_idx["founder1_allele"]],
                "founder2_allele": fields[col_idx["founder2_allele"]],
            }


def chrom_sort_key(chrom):
    if chrom.startswith("chr"):
        suffix = chrom[3:]
        if suffix.isdigit():
            return (0, int(suffix))
        if suffix == "X":
            return (1, 23)
        if suffix == "Y":
            return (1, 24)
        if suffix in ("M", "MT"):
            return (1, 25)
    return (2, chrom)


def empty_site_record():
    rec = {
        "n_animals": 0,
        "n_missing": 0,
        "n_missing_sample": 0,
        "n_missing_both": 0,
        "n_missing_founder": 0,
        "n_mismatch_animals": 0,
        "expected": {f: 0.0 for f in FOUNDERS},
        "mismatch": {f: 0.0 for f in FOUNDERS},
        "expected_total_alleles": 0.0,
        "mismatch_total_alleles": 0.0,
    }
    return rec


def founder_mismatch_contributions(founder1, founder2, allele1, allele2, sample_gt):
    observed = [sample_gt[0], sample_gt[1]]
    expected = [(founder1, allele1), (founder2, allele2)]

    best_mismatch_total = None
    best_founder_contribs = []

    for perm in set(permutations(observed, 2)):
        mismatch_total = 0
        contrib = defaultdict(float)

        for i in range(2):
            founder, expected_allele = expected[i]
            observed_allele = perm[i]

            if expected_allele != observed_allele:
                mismatch_total += 1
                contrib[founder] += 1.0

        if best_mismatch_total is None or mismatch_total < best_mismatch_total:
            best_mismatch_total = mismatch_total
            best_founder_contribs = [contrib]
        elif mismatch_total == best_mismatch_total:
            best_founder_contribs.append(contrib)

    mean_contrib = {f: 0.0 for f in FOUNDERS}

    for contrib in best_founder_contribs:
        for founder in FOUNDERS:
            mean_contrib[founder] += contrib.get(founder, 0.0)

    n_best = float(len(best_founder_contribs))
    for founder in FOUNDERS:
        mean_contrib[founder] /= n_best

    return mean_contrib, float(best_mismatch_total)


def main():
    ap = argparse.ArgumentParser(
        description="Summarize site-level non-concordance across animals."
    )
    ap.add_argument("--indir", required=True, help="Directory of per-animal non-concordance BED files")
    ap.add_argument("--out", required=True, help="Output TSV file")
    args = ap.parse_args()

    bed_files = list_bed_files(args.indir)
    if len(bed_files) == 0:
        raise SystemExit(f"ERROR: no .bed or .bed.gz files found in {args.indir}")

    sys.stdout.write(f"Found {len(bed_files)} BED files\n")

    site_data = {}

    for bed_path in bed_files:
        sys.stdout.write(f"Reading: {bed_path}\n")

        seen_in_this_file = set()

        for rec in iter_nonconcordance_records(bed_path):
            chrom = rec["chrom"]
            start = rec["start"]
            end = rec["end"]
            outcome = rec["outcome"]
            founder1 = rec["founder1"]
            founder2 = rec["founder2"]

            key = (chrom, start, end)

            if key in seen_in_this_file:
                continue
            seen_in_this_file.add(key)

            if founder1 in ("", ".", "NA") or founder2 in ("", ".", "NA"):
                continue

            if key not in site_data:
                site_data[key] = empty_site_record()

            site_data[key]["n_animals"] += 1

            if outcome not in ("Missing_Founder", "Missing_Both"):
                site_data[key]["expected"][founder1] += 1.0
                site_data[key]["expected"][founder2] += 1.0
                site_data[key]["expected_total_alleles"] += 2.0

            if outcome in ("Missing_Sample", "Missing_Both"):
                site_data[key]["n_missing"] += 1

            if outcome == "Missing_Sample":
                site_data[key]["n_missing_sample"] += 1
            elif outcome == "Missing_Both":
                site_data[key]["n_missing_both"] += 1
            elif outcome == "Missing_Founder":
                site_data[key]["n_missing_founder"] += 1
            elif outcome == "Mismatch":
                site_data[key]["n_mismatch_animals"] += 1

                sample_gt = parse_gt_field(rec["sample_gt"])
                try:
                    allele1 = int(rec["founder1_allele"])
                    allele2 = int(rec["founder2_allele"])
                except ValueError:
                    continue

                if sample_gt is None:
                    continue

                founder_contrib, mismatch_total = founder_mismatch_contributions(
                    founder1=founder1,
                    founder2=founder2,
                    allele1=allele1,
                    allele2=allele2,
                    sample_gt=sample_gt,
                )

                for founder in FOUNDERS:
                    site_data[key]["mismatch"][founder] += founder_contrib[founder]

                site_data[key]["mismatch_total_alleles"] += mismatch_total

    with open(args.out, "w") as out:
        header = [
            "chrom",
            "start",
            "end",
            "n_animals",
            "n_missing",
            "n_missing_sample",
            "n_missing_both",
            "n_missing_founder",
            "n_mismatch_animals",
            "expected_total_alleles",
            "mismatch_total_alleles",
        ]

        for founder in FOUNDERS:
            header.append(f"expected_{founder}")

        for founder in FOUNDERS:
            header.append(f"mismatch_{founder}")

        out.write("\t".join(header) + "\n")

        for chrom, start, end in sorted(
            site_data.keys(),
            key=lambda x: (chrom_sort_key(x[0]), x[1], x[2]),
        ):
            rec = site_data[(chrom, start, end)]

            row = [
                chrom,
                str(start),
                str(end),
                str(rec["n_animals"]),
                str(rec["n_missing"]),
                str(rec["n_missing_sample"]),
                str(rec["n_missing_both"]),
                str(rec["n_missing_founder"]),
                str(rec["n_mismatch_animals"]),
                f"{rec['expected_total_alleles']:.6f}",
                f"{rec['mismatch_total_alleles']:.6f}",
            ]

            for founder in FOUNDERS:
                row.append(f"{rec['expected'][founder]:.6f}")

            for founder in FOUNDERS:
                row.append(f"{rec['mismatch'][founder]:.6f}")

            out.write("\t".join(row) + "\n")

    sys.stdout.write(f"Wrote: {args.out}\n")


if __name__ == "__main__":
    main()