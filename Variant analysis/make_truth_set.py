#!/usr/bin/env python3

import argparse
import csv
import os
import sys

try:
    import pysam
except ImportError:
    sys.exit(
        "ERROR: This script requires pysam. Try installing/loading pysam, "
        "or run inside an environment where pysam is available."
    )


FOUNDER_LETTER_TO_VCF_SAMPLE = {
    "A": "A_J",
    "B": "REF",
    "C": "129S1_SvImJ",
    "D": "NOD_ShiLtJ",
    "E": "NZO_HlLtJ",
    "F": "CAST_EiJ_T2T_Keane",
    "G": "PWK_PhJ",
    "H": "WSB_EiJ",
}


def write_text_or_bgzip(path):
    """
    Return a write function and close function.

    If output ends with .gz, write BGZF-compressed output so bcftools
    can index it directly.
    """

    if path == "-":
        def write(s):
            sys.stdout.write(s)

        def close():
            pass

        return write, close

    if path.endswith(".gz"):
        handle = pysam.BGZFile(path, "w")

        def write(s):
            handle.write(s.encode())

        def close():
            handle.close()

        return write, close

    handle = open(path, "w")

    def write(s):
        handle.write(s)

    def close():
        handle.close()

    return write, close


def get_required(row, key, path, line_number):
    value = row.get(key)
    if value is None or value == "":
        raise ValueError(
            "{}:{} missing required column/value: {}".format(
                path, line_number, key
            )
        )
    return value


def load_blocks(path, target_sample=None):
    """
    Load parsed block TSV.

    Expected columns from the earlier parser:
      sample, chrom, start_1based, end_exclusive,
      top_haplotype, bottom_haplotype,
      optionally top_vcf_sample, bottom_vcf_sample

    If top_vcf_sample/bottom_vcf_sample are absent, this script maps
    founder letters using FOUNDER_LETTER_TO_VCF_SAMPLE.
    """

    rows = []
    samples_seen = set()

    with open(path, newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")

        for line_number, row in enumerate(reader, start=2):
            sample = get_required(row, "sample", path, line_number)
            samples_seen.add(sample)

            if target_sample is not None and sample != target_sample:
                continue

            chrom = get_required(row, "chrom", path, line_number)
            start = int(get_required(row, "start_1based", path, line_number))
            end_exclusive = int(get_required(row, "end_exclusive", path, line_number))

            top_hap = get_required(row, "top_haplotype", path, line_number)
            bottom_hap = get_required(row, "bottom_haplotype", path, line_number)

            top_vcf_sample = row.get("top_vcf_sample") or FOUNDER_LETTER_TO_VCF_SAMPLE[top_hap]
            bottom_vcf_sample = row.get("bottom_vcf_sample") or FOUNDER_LETTER_TO_VCF_SAMPLE[bottom_hap]

            if end_exclusive <= start:
                continue

            rows.append(
                {
                    "sample": sample,
                    "chrom": chrom,
                    "start": start,
                    "end_exclusive": end_exclusive,
                    "top_hap": top_hap,
                    "bottom_hap": bottom_hap,
                    "top_vcf_sample": top_vcf_sample,
                    "bottom_vcf_sample": bottom_vcf_sample,
                }
            )

    if target_sample is None:
        if len(samples_seen) != 1:
            raise ValueError(
                "Parsed block TSV contains multiple samples. "
                "Please provide --sample. Samples seen: {}".format(
                    ", ".join(sorted(samples_seen))
                )
            )

    if not rows:
        raise ValueError("No usable block rows found in {}".format(path))

    return rows


def is_missing_gt(gt):
    if gt is None:
        return True

    if len(gt) == 0:
        return True

    return any(allele is None for allele in gt)


def get_haploid_allele(record, vcf_sample, ref_sentinel="REF"):
    """
    Return one allele index for one homolog.

    REF sentinel means this homolog is the reference founder, so it
    contributes allele 0 without needing a VCF sample column.

    For real VCF samples, require a non-missing haploid GT.
    """

    if vcf_sample == ref_sentinel:
        return 0

    if vcf_sample not in record.samples:
        raise KeyError(
            "VCF sample '{}' not found in truth VCF header".format(vcf_sample)
        )

    gt = record.samples[vcf_sample].get("GT")

    if is_missing_gt(gt):
        return None

    if len(gt) != 1:
        raise ValueError(
            "Expected haploid GT for sample {}, but saw GT={} at {}:{}".format(
                vcf_sample, gt, record.chrom, record.pos
            )
        )

    return gt[0]


def parse_contig_order(vcf):
    return {name: i for i, name in enumerate(vcf.header.contigs)}


def block_sort_key(block, contig_order):
    chrom = block["chrom"]

    if chrom in contig_order:
        chrom_key = contig_order[chrom]
    else:
        # Put unknown contigs after known VCF contigs.
        chrom_key = len(contig_order) + 1

    return chrom_key, block["start"], block["end_exclusive"]


def write_output_header(input_vcf, write, output_sample_name):
    header_text = str(input_vcf.header)
    has_gt_header = False

    for line in header_text.splitlines():
        if line.startswith("##FORMAT=<ID=GT,"):
            has_gt_header = True

        if line.startswith("##"):
            write(line + "\n")

    if not has_gt_header:
        write(
            '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">\n'
        )

    write(
        '##make_diploid_truth_from_blocks='
        '"Constructed by combining haploid founder truth-set genotypes across parsed haplotype blocks"\n'
    )

    write(
        "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t{}\n".format(
            output_sample_name
        )
    )


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Construct a per-organism diploid truth VCF from a multi-sample "
            "haploid founder truth VCF and parsed haplotype block TSV."
        )
    )

    parser.add_argument(
        "--truth-vcf",
        required=True,
        help="Indexed multi-sample founder truth VCF/BCF. Usually .vcf.gz plus .tbi/.csi.",
    )

    parser.add_argument(
        "--blocks",
        required=True,
        help="Parsed block TSV from the earlier haplotype-block parser.",
    )

    parser.add_argument(
        "--output",
        required=True,
        help="Output VCF. Use .vcf.gz for BGZF-compressed output.",
    )

    parser.add_argument(
        "--sample",
        default=None,
        help=(
            "Organism/sample name from the parsed block TSV. Required if the TSV "
            "contains more than one organism."
        ),
    )

    parser.add_argument(
        "--output-sample-name",
        default=None,
        help=(
            "Sample name to use in the output VCF. Default: same as --sample, "
            "or the sole sample in the block TSV."
        ),
    )

    parser.add_argument(
        "--ref-sentinel",
        default="REF",
        help=(
            "Mapped VCF sample value that means reference founder / allele 0, "
            "not a real VCF sample. Default: REF."
        ),
    )

    parser.add_argument(
        "--phased",
        action="store_true",
        help="Write GTs as a|b instead of a/b.",
    )

    parser.add_argument(
        "--keep-hom-ref",
        action="store_true",
        help=(
            "Keep synthesized 0/0 records. Default is to skip them, producing "
            "a variant-only truth VCF."
        ),
    )

    args = parser.parse_args()

    blocks = load_blocks(args.blocks, target_sample=args.sample)

    if args.output_sample_name is not None:
        output_sample_name = args.output_sample_name
    elif args.sample is not None:
        output_sample_name = args.sample
    else:
        output_sample_name = blocks[0]["sample"]

    truth_vcf = pysam.VariantFile(args.truth_vcf)
    contig_order = parse_contig_order(truth_vcf)
    blocks.sort(key=lambda b: block_sort_key(b, contig_order))

    # Check real VCF sample names up front.
    needed_samples = set()

    for block in blocks:
        for key in ["top_vcf_sample", "bottom_vcf_sample"]:
            sample_name = block[key]
            if sample_name != args.ref_sentinel:
                needed_samples.add(sample_name)

    missing_samples = sorted(
        sample_name for sample_name in needed_samples
        if sample_name not in truth_vcf.header.samples
    )

    if missing_samples:
        raise ValueError(
            "These mapped founder samples were not found in the truth VCF: {}".format(
                ", ".join(missing_samples)
            )
        )

    write, close = write_text_or_bgzip(args.output)

    emitted = {}
    n_seen = 0
    n_written = 0
    n_missing = 0
    n_hom_ref_skipped = 0
    n_duplicate_same = 0

    sep = "|" if args.phased else "/"

    try:
        write_output_header(truth_vcf, write, output_sample_name)

        for block in blocks:
            chrom = block["chrom"]
            start = block["start"]
            end_exclusive = block["end_exclusive"]

            top_sample = block["top_vcf_sample"]
            bottom_sample = block["bottom_vcf_sample"]

            # If both homologs are reference, there are no variant records
            # to pull for a variant-only truth VCF.
            if (
                top_sample == args.ref_sentinel
                and bottom_sample == args.ref_sentinel
                and not args.keep_hom_ref
            ):
                continue

            if chrom not in truth_vcf.header.contigs:
                raise ValueError(
                    "Chromosome {} from block file is not present in truth VCF header".format(
                        chrom
                    )
                )

            # pysam fetch uses 0-based, half-open coordinates.
            # Our block TSV uses 1-based start, end-exclusive.
            # So records with POS start <= POS < end_exclusive are fetched by:
            fetch_start_0 = start - 1
            fetch_end_0 = end_exclusive - 1

            for record in truth_vcf.fetch(chrom, fetch_start_0, fetch_end_0):
                n_seen += 1

                # Defensive check; fetch should already enforce this.
                if record.pos < start or record.pos >= end_exclusive:
                    continue

                top_allele = get_haploid_allele(
                    record, top_sample, ref_sentinel=args.ref_sentinel
                )
                bottom_allele = get_haploid_allele(
                    record, bottom_sample, ref_sentinel=args.ref_sentinel
                )

                if top_allele is None or bottom_allele is None:
                    n_missing += 1
                    continue

                if top_allele == 0 and bottom_allele == 0 and not args.keep_hom_ref:
                    n_hom_ref_skipped += 1
                    continue

                out_gt = "{}{}{}".format(top_allele, sep, bottom_allele)

                record_key = (
                    record.chrom,
                    record.pos,
                    record.id,
                    record.ref,
                    tuple(record.alts or []),
                )

                if record_key in emitted:
                    previous_gt = emitted[record_key]

                    if previous_gt != out_gt:
                        raise ValueError(
                            "Record {}:{} was reached more than once with different GTs: {} vs {}".format(
                                record.chrom, record.pos, previous_gt, out_gt
                            )
                        )

                    n_duplicate_same += 1
                    continue

                emitted[record_key] = out_gt

                fields = str(record).rstrip("\n").split("\t")
                fixed_fields = fields[:8]

                write("\t".join(fixed_fields + ["GT", out_gt]) + "\n")
                n_written += 1

    finally:
        close()
        truth_vcf.close()

    print("Done.", file=sys.stderr)
    print("Records scanned: {}".format(n_seen), file=sys.stderr)
    print("Records written: {}".format(n_written), file=sys.stderr)
    print("Skipped due to missing founder GT: {}".format(n_missing), file=sys.stderr)
    print("Skipped synthesized 0/0 records: {}".format(n_hom_ref_skipped), file=sys.stderr)
    print("Skipped duplicate records with same GT: {}".format(n_duplicate_same), file=sys.stderr)


if __name__ == "__main__":
    main()
