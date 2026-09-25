#!/usr/bin/env python3

import os
import re
import gzip
import math
import argparse
from collections import Counter


def parse_args():
    parser = argparse.ArgumentParser(
        description="Collect DeepVariant QC metrics from VCF.gz files into compact TSV tables for plotting in R."
    )
    parser.add_argument(
        "--vcf_dir",
        required=True,
        help="Directory containing DeepVariant VCF.gz files"
    )
    parser.add_argument(
        "--out_prefix",
        required=True,
        help="Prefix for output TSV files"
    )
    parser.add_argument(
        "--vaf_bin_width",
        type=float,
        default=0.01,
        help="Width of VAF histogram bins. Default: 0.01"
    )
    return parser.parse_args()


def find_vcf_files(vcf_dir):
    vcf_files = []

    for root, dirs, files in os.walk(vcf_dir):
        for name in files:
            if name.endswith(".vcf.gz") and not name.endswith(".vcf.gz.tbi"):
                vcf_files.append(os.path.join(root, name))

    vcf_files.sort()

    if len(vcf_files) == 0:
        raise RuntimeError("No .vcf.gz files found under: " + vcf_dir)

    return vcf_files


def parse_sample_and_method(path):
    file_base = os.path.basename(path)
    parent_dir = os.path.basename(os.path.dirname(path))

    if re.match(r"^CC[0-9]{3}-", parent_dir):
        sample_id = re.sub(r"^((CC[0-9]{3})).*$", r"\1", parent_dir)
        method = re.sub(r"^CC[0-9]{3}-", "", parent_dir)
        return sample_id, method

    match = re.match(r"^(.*)_(CC[0-9]{3})\.vcf\.gz$", file_base)
    if match:
        method = match.group(1)
        sample_id = match.group(2)
        return sample_id, method

    raise RuntimeError("Could not parse sample/method from file path: " + path)


def safe_int(value):
    if value is None or value == "" or value == ".":
        return None
    try:
        return int(float(value))
    except Exception:
        return None


def safe_float(value):
    if value is None or value == "" or value == ".":
        return None
    try:
        x = float(value)
        if math.isnan(x) or math.isinf(x):
            return None
        return x
    except Exception:
        return None


def add_vaf_bin(counter, value, bin_width):
    x = safe_float(value)
    if x is None:
        return False

    if x < 0:
        x = 0.0
    if x > 1:
        x = 1.0

    n_bins = int(round(1.0 / bin_width))
    bin_index = int(math.floor(x / bin_width))

    if bin_index >= n_bins:
        bin_index = n_bins - 1
    if bin_index < 0:
        bin_index = 0

    counter[bin_index] += 1
    return True


def weighted_median_from_counter(counter):
    if len(counter) == 0:
        return None

    total = sum(counter.values())
    if total == 0:
        return None

    pos1 = (total + 1) // 2
    pos2 = (total + 2) // 2

    cumulative = 0
    val1 = None
    val2 = None

    for value in sorted(counter.keys()):
        cumulative += counter[value]

        if val1 is None and cumulative >= pos1:
            val1 = value
        if val2 is None and cumulative >= pos2:
            val2 = value
            break

    if val1 is None or val2 is None:
        return None

    return (val1 + val2) / 2.0


def weighted_median_from_binned_counter(counter, bin_width):
    if len(counter) == 0:
        return None

    total = sum(counter.values())
    if total == 0:
        return None

    pos1 = (total + 1) // 2
    pos2 = (total + 2) // 2

    cumulative = 0
    idx1 = None
    idx2 = None

    for bin_index in sorted(counter.keys()):
        cumulative += counter[bin_index]

        if idx1 is None and cumulative >= pos1:
            idx1 = bin_index
        if idx2 is None and cumulative >= pos2:
            idx2 = bin_index
            break

    if idx1 is None or idx2 is None:
        return None

    mid1 = (idx1 * bin_width) + (bin_width / 2.0)
    mid2 = (idx2 * bin_width) + (bin_width / 2.0)

    if mid1 > 1.0:
        mid1 = 1.0
    if mid2 > 1.0:
        mid2 = 1.0

    return (mid1 + mid2) / 2.0


def main():
    args = parse_args()

    vcf_files = find_vcf_files(args.vcf_dir)
    print("Found", len(vcf_files), "VCF files")

    filter_counts = {}
    gq_counts = {}
    dp_counts = {}
    vaf_bin_counts = {}
    sample_summary = {}

    for i, path in enumerate(vcf_files, start=1):
        sample_id, method = parse_sample_and_method(path)
        key = (sample_id, method)

        filter_counts[key] = Counter()
        gq_counts[key] = Counter()
        dp_counts[key] = Counter()
        vaf_bin_counts[key] = Counter()

        sample_summary[key] = {
            "n_sites": 0,
            "n_nonmissing_gq": 0,
            "n_nonmissing_dp": 0,
            "n_nonmissing_vaf": 0
        }

        with gzip.open(path, "rt") as fh:
            header_fields = None

            for line in fh:
                if line.startswith("##"):
                    continue
                if line.startswith("#CHROM"):
                    header_fields = line.rstrip("\n").split("\t")
                    break

            if header_fields is None:
                raise RuntimeError("Did not find #CHROM header in: " + path)

            if len(header_fields) < 10:
                raise RuntimeError("Expected sample column in VCF: " + path)

            for line in fh:
                if not line:
                    continue

                fields = line.rstrip("\n").split("\t")
                if len(fields) < 10:
                    continue

                filt = fields[6]
                fmt = fields[8].split(":")
                samp = fields[9].split(":")

                fmt_map = {}
                for j in range(min(len(fmt), len(samp))):
                    fmt_map[fmt[j]] = samp[j]

                sample_summary[key]["n_sites"] += 1
                filter_counts[key][filt] += 1

                gq = safe_int(fmt_map.get("GQ"))
                if gq is not None:
                    gq_counts[key][gq] += 1
                    sample_summary[key]["n_nonmissing_gq"] += 1

                dp = safe_int(fmt_map.get("DP"))
                if dp is not None:
                    dp_counts[key][dp] += 1
                    sample_summary[key]["n_nonmissing_dp"] += 1

                added_vaf = add_vaf_bin(vaf_bin_counts[key], fmt_map.get("VAF"), args.vaf_bin_width)
                if added_vaf:
                    sample_summary[key]["n_nonmissing_vaf"] += 1

        print(str(i) + " / " + str(len(vcf_files)) + " imported: " + os.path.basename(path))

    filter_path = args.out_prefix + ".filter_counts.tsv"
    gq_path = args.out_prefix + ".gq_counts.tsv"
    dp_path = args.out_prefix + ".dp_counts.tsv"
    vaf_path = args.out_prefix + ".vaf_bins.tsv"
    summary_path = args.out_prefix + ".sample_summary.tsv"

    with open(filter_path, "w") as out:
        out.write("sample\tmethod\tfilter\tcount\tfraction_of_all_sites\n")
        for sample_id, method in sorted(filter_counts.keys()):
            total = sample_summary[(sample_id, method)]["n_sites"]
            for filt in sorted(filter_counts[(sample_id, method)].keys()):
                count = filter_counts[(sample_id, method)][filt]
                fraction = count / total if total > 0 else "NA"
                out.write(
                    sample_id + "\t" +
                    method + "\t" +
                    filt + "\t" +
                    str(count) + "\t" +
                    str(fraction) + "\n"
                )

    with open(gq_path, "w") as out:
        out.write("sample\tmethod\tgq\tcount\tfraction_of_nonmissing_gq\n")
        for sample_id, method in sorted(gq_counts.keys()):
            total = sample_summary[(sample_id, method)]["n_nonmissing_gq"]
            for gq in sorted(gq_counts[(sample_id, method)].keys()):
                count = gq_counts[(sample_id, method)][gq]
                fraction = count / total if total > 0 else "NA"
                out.write(
                    sample_id + "\t" +
                    method + "\t" +
                    str(gq) + "\t" +
                    str(count) + "\t" +
                    str(fraction) + "\n"
                )

    with open(dp_path, "w") as out:
        out.write("sample\tmethod\tdp\tcount\tfraction_of_nonmissing_dp\n")
        for sample_id, method in sorted(dp_counts.keys()):
            total = sample_summary[(sample_id, method)]["n_nonmissing_dp"]
            for dp in sorted(dp_counts[(sample_id, method)].keys()):
                count = dp_counts[(sample_id, method)][dp]
                fraction = count / total if total > 0 else "NA"
                out.write(
                    sample_id + "\t" +
                    method + "\t" +
                    str(dp) + "\t" +
                    str(count) + "\t" +
                    str(fraction) + "\n"
                )

    with open(vaf_path, "w") as out:
        out.write("sample\tmethod\tbin_index\tbin_start\tbin_end\tbin_mid\tcount\tfraction_of_nonmissing_vaf\n")
        for sample_id, method in sorted(vaf_bin_counts.keys()):
            total = sample_summary[(sample_id, method)]["n_nonmissing_vaf"]
            for bin_index in sorted(vaf_bin_counts[(sample_id, method)].keys()):
                bin_start = bin_index * args.vaf_bin_width
                bin_end = bin_start + args.vaf_bin_width
                if bin_end > 1.0:
                    bin_end = 1.0
                bin_mid = bin_start + ((bin_end - bin_start) / 2.0)
                count = vaf_bin_counts[(sample_id, method)][bin_index]
                fraction = count / total if total > 0 else "NA"
                out.write(
                    sample_id + "\t" +
                    method + "\t" +
                    str(bin_index) + "\t" +
                    str(bin_start) + "\t" +
                    str(bin_end) + "\t" +
                    str(bin_mid) + "\t" +
                    str(count) + "\t" +
                    str(fraction) + "\n"
                )

    with open(summary_path, "w") as out:
        out.write(
            "sample\tmethod\tn_sites\tn_nonmissing_gq\tn_nonmissing_dp\tn_nonmissing_vaf\t"
            "median_gq\tmedian_dp\tapprox_median_vaf\tpass_count\tpass_fraction\trefcall_count\trefcall_fraction\n"
        )

        for sample_id, method in sorted(sample_summary.keys()):
            key = (sample_id, method)

            n_sites = sample_summary[key]["n_sites"]
            n_nonmissing_gq = sample_summary[key]["n_nonmissing_gq"]
            n_nonmissing_dp = sample_summary[key]["n_nonmissing_dp"]
            n_nonmissing_vaf = sample_summary[key]["n_nonmissing_vaf"]

            median_gq = weighted_median_from_counter(gq_counts[key])
            median_dp = weighted_median_from_counter(dp_counts[key])
            median_vaf = weighted_median_from_binned_counter(vaf_bin_counts[key], args.vaf_bin_width)

            pass_count = filter_counts[key].get("PASS", 0)
            refcall_count = filter_counts[key].get("RefCall", 0)

            pass_fraction = (pass_count / n_sites) if n_sites > 0 else "NA"
            refcall_fraction = (refcall_count / n_sites) if n_sites > 0 else "NA"

            out.write(
                sample_id + "\t" +
                method + "\t" +
                str(n_sites) + "\t" +
                str(n_nonmissing_gq) + "\t" +
                str(n_nonmissing_dp) + "\t" +
                str(n_nonmissing_vaf) + "\t" +
                str(median_gq if median_gq is not None else "NA") + "\t" +
                str(median_dp if median_dp is not None else "NA") + "\t" +
                str(median_vaf if median_vaf is not None else "NA") + "\t" +
                str(pass_count) + "\t" +
                str(pass_fraction) + "\t" +
                str(refcall_count) + "\t" +
                str(refcall_fraction) + "\n"
            )

    print("Wrote:", filter_path)
    print("Wrote:", gq_path)
    print("Wrote:", dp_path)
    print("Wrote:", vaf_path)
    print("Wrote:", summary_path)


if __name__ == "__main__":
    main()