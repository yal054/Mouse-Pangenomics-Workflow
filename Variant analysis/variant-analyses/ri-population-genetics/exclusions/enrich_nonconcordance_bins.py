#!/usr/bin/env python3
import argparse
import gzip
import os
import random
import sys
from collections import defaultdict


def open_text_maybe_gzip(path):
    if path.endswith(".gz"):
        return gzip.open(path, "rt")
    return open(path, "r")


def parse_fai(fai_path):
    chrom_order = []
    chrom_sizes = {}

    with open(fai_path, "r") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            fields = line.split("\t")
            if len(fields) < 2:
                raise ValueError(f"Malformed .fai line: {raw.rstrip()}")
            chrom = fields[0]
            size = int(fields[1])
            chrom_order.append(chrom)
            chrom_sizes[chrom] = size

    if not chrom_order:
        raise ValueError(f"No chromosome sizes found in: {fai_path}")

    return chrom_order, chrom_sizes


def list_bed_files(indir):
    files = []
    for name in sorted(os.listdir(indir)):
        path = os.path.join(indir, name)
        if not os.path.isfile(path):
            continue
        if name.endswith(".bed") or name.endswith(".bed.gz"):
            files.append(path)
    return files


def strip_bed_suffix(path):
    base = os.path.basename(path)
    if base.endswith(".gz"):
        base = base[:-3]
    if base.endswith(".bed"):
        base = base[:-4]
    return base


def iter_nonconcordance_bed(path):
    with open_text_maybe_gzip(path) as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            if line.startswith("#"):
                continue

            fields = line.split("\t")
            if len(fields) < 4:
                continue

            if fields[0] == "chrom" and fields[1] == "start":
                continue

            chrom = fields[0]
            start = int(fields[1])
            end = int(fields[2])
            outcome = fields[3]

            yield chrom, start, end, outcome


def site_to_bin_range(pos0, window_size, step_size, n_bins):
    first = (pos0 - window_size + 1 + step_size - 1) // step_size
    if first < 0:
        first = 0
    last = pos0 // step_size
    if last >= n_bins:
        last = n_bins - 1

    if first > last:
        return None

    return first, last + 1


def analyze_one_outcome(
    outcome,
    site_counts_by_chrom,
    chrom_order,
    chrom_sizes,
    window_size,
    step_size,
    n_shuffles,
    seed,
    out_handle,
    n_samples_total,
):
    sys.stdout.write(f"Analyzing outcome class: {outcome}\n")

    for chrom_index, chrom in enumerate(chrom_order):
        chrom_size = chrom_sizes[chrom]
        n_bins = ((chrom_size - 1) // step_size) + 1

        bin_site_counts = [0] * n_bins
        bin_obs_sum_animals = [0.0] * n_bins
        bin_null_sum_means = [0.0] * n_bins
        bin_null_ge_obs = [0] * n_bins

        pos_to_count = site_counts_by_chrom.get(chrom, {})
        positions = sorted(pos_to_count.keys())
        counts = [pos_to_count[p] for p in positions]

        site_bin_ranges = []

        for pos0, count in zip(positions, counts):
            r = site_to_bin_range(pos0, window_size, step_size, n_bins)
            if r is None:
                site_bin_ranges.append(None)
                continue

            first_bin, last_bin_exclusive = r
            site_bin_ranges.append((first_bin, last_bin_exclusive))

            for b in range(first_bin, last_bin_exclusive):
                bin_site_counts[b] += 1
                bin_obs_sum_animals[b] += count

        if n_shuffles > 0 and len(counts) > 0:
            rng = random.Random(seed + (chrom_index + 1) * 1000003)

            perm = list(range(len(counts)))

            for _ in range(n_shuffles):
                rng.shuffle(perm)

                shuffled_bin_sum_animals = [0.0] * n_bins

                for site_index, r in enumerate(site_bin_ranges):
                    if r is None:
                        continue
                    first_bin, last_bin_exclusive = r
                    shuffled_count = counts[perm[site_index]]
                    for b in range(first_bin, last_bin_exclusive):
                        shuffled_bin_sum_animals[b] += shuffled_count

                for b in range(n_bins):
                    if bin_site_counts[b] > 0:
                        obs_mean = bin_obs_sum_animals[b] / bin_site_counts[b]
                        shuf_mean = shuffled_bin_sum_animals[b] / bin_site_counts[b]
                    else:
                        obs_mean = 0.0
                        shuf_mean = 0.0

                    bin_null_sum_means[b] += shuf_mean
                    if shuf_mean >= obs_mean:
                        bin_null_ge_obs[b] += 1

        for b in range(n_bins):
            start = b * step_size
            end = start + window_size
            if end > chrom_size:
                end = chrom_size

            n_sites = bin_site_counts[b]

            if n_sites > 0:
                obs_mean_animals_per_site = bin_obs_sum_animals[b] / n_sites
            else:
                obs_mean_animals_per_site = 0.0

            if n_shuffles > 0:
                null_mean_animals_per_site = bin_null_sum_means[b] / n_shuffles
                empirical_p_upper = (bin_null_ge_obs[b] + 1.0) / (n_shuffles + 1.0)
            else:
                null_mean_animals_per_site = 0.0
                empirical_p_upper = "NA"

            if null_mean_animals_per_site == 0:
                if obs_mean_animals_per_site == 0:
                    oe_ratio = "NA"
                else:
                    oe_ratio = "Inf"
            else:
                oe_ratio = f"{obs_mean_animals_per_site / null_mean_animals_per_site:.10f}"

            if isinstance(empirical_p_upper, str):
                empirical_p_upper_str = empirical_p_upper
            else:
                empirical_p_upper_str = f"{empirical_p_upper:.10f}"

            out_handle.write(
                f"{chrom}\t{start}\t{end}\t{outcome}\t"
                f"{n_sites}\t"
                f"{bin_obs_sum_animals[b]:.10f}\t"
                f"{obs_mean_animals_per_site:.10f}\t"
                f"{null_mean_animals_per_site:.10f}\t"
                f"{oe_ratio}\t"
                f"{empirical_p_upper_str}\t"
                f"{n_shuffles}\t"
                f"{n_samples_total}\n"
            )


def main():
    ap = argparse.ArgumentParser(
        description="Identify genomic bins enriched for non-concordant outcome classes from per-animal positional BED files."
    )
    ap.add_argument("--indir", required=True, help="Directory containing per-animal non-concordance BED files")
    ap.add_argument("--fai", required=True, help="FAI file with chromosome sizes")
    ap.add_argument("--out", required=True, help="Output BED-like results file")
    ap.add_argument("--window-size", type=int, default=10000, help="Window size in bp")
    ap.add_argument("--step-size", type=int, default=10000, help="Step size in bp")
    ap.add_argument("--n-shuffles", type=int, default=50, help="Number of shuffles")
    ap.add_argument("--seed", type=int, default=1, help="Random seed")
    ap.add_argument(
        "--outcomes",
        default="",
        help="Comma-delimited list of outcomes to include. Default is all observed outcomes except Match and Outside_Mosaic."
    )
    args = ap.parse_args()

    if args.window_size <= 0:
        raise SystemExit("ERROR: --window-size must be > 0")
    if args.step_size <= 0:
        raise SystemExit("ERROR: --step-size must be > 0")
    if args.n_shuffles < 0:
        raise SystemExit("ERROR: --n-shuffles must be >= 0")

    sys.stdout.write("Reading chromosome sizes...\n")
    chrom_order, chrom_sizes = parse_fai(args.fai)

    sys.stdout.write("Scanning BED directory...\n")
    bed_files = list_bed_files(args.indir)
    if len(bed_files) == 0:
        raise SystemExit(f"ERROR: no .bed or .bed.gz files found in {args.indir}")

    sys.stdout.write(f"Found {len(bed_files)} BED files\n")

    requested_outcomes = set()
    if args.outcomes.strip():
        requested_outcomes = set(x.strip() for x in args.outcomes.split(",") if x.strip())

    excluded_by_default = {"Match", "Outside_Mosaic"}

    site_counts = defaultdict(lambda: defaultdict(lambda: defaultdict(int)))
    all_observed_outcomes = set()

    for bed_path in bed_files:
        sample_name = strip_bed_suffix(bed_path)
        sys.stdout.write(f"Reading: {bed_path} ({sample_name})\n")

        seen_in_this_file = set()

        for chrom, start, end, outcome in iter_nonconcordance_bed(bed_path):
            all_observed_outcomes.add(outcome)

            if requested_outcomes:
                if outcome not in requested_outcomes:
                    continue
            else:
                if outcome in excluded_by_default:
                    continue

            if chrom not in chrom_sizes:
                continue

            key = (outcome, chrom, start, end)
            if key in seen_in_this_file:
                continue
            seen_in_this_file.add(key)

            site_counts[outcome][chrom][start] += 1

    if requested_outcomes:
        outcomes_to_analyze = [x for x in sorted(requested_outcomes) if x in site_counts]
    else:
        outcomes_to_analyze = sorted(site_counts.keys())

    if len(outcomes_to_analyze) == 0:
        raise SystemExit("ERROR: no outcome classes remained after filtering")

    sys.stdout.write("Outcome classes to analyze:\n")
    for outcome in outcomes_to_analyze:
        sys.stdout.write(f"  {outcome}\n")

    with open(args.out, "w") as out:
        out.write(
            "chrom\tstart\tend\toutcome\t"
            "n_sites_in_bin\t"
            "obs_sum_animals\t"
            "obs_mean_animals_per_site\t"
            "null_mean_animals_per_site\t"
            "oe_ratio\t"
            "empirical_p_upper\t"
            "n_shuffles\t"
            "n_samples_total\n"
        )

        for outcome_index, outcome in enumerate(outcomes_to_analyze):
            analyze_one_outcome(
                outcome=outcome,
                site_counts_by_chrom=site_counts[outcome],
                chrom_order=chrom_order,
                chrom_sizes=chrom_sizes,
                window_size=args.window_size,
                step_size=args.step_size,
                n_shuffles=args.n_shuffles,
                seed=args.seed + outcome_index * 10000019,
                out_handle=out,
                n_samples_total=len(bed_files),
            )

    sys.stdout.write(f"Wrote: {args.out}\n")


if __name__ == "__main__":
    main()