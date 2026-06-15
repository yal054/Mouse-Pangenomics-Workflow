#!/usr/bin/env python3

import argparse
import csv
import os
import re
import sys
from collections import defaultdict, namedtuple

Block = namedtuple("Block", ["chrom", "start", "end", "hap"])


def warn_or_fail(msg, strict=True):
    if strict:
        raise ValueError(msg)
    print("WARNING:", msg, file=sys.stderr)


def chrom_sort_key(chrom):
    m = re.match(r"^chr(\d+)$", chrom)
    if m:
        return int(m.group(1))
    return chrom


def parse_autosomes(autosomes_arg):
    if autosomes_arg == "mouse":
        return set("chr{}".format(i) for i in range(1, 20))

    autosomes = set()
    for chrom in autosomes_arg.split(","):
        chrom = chrom.strip()
        if chrom:
            autosomes.add(chrom)
    return autosomes


def fallback_sample_name(path):
    name = os.path.basename(path)

    # Strip common double extensions first.
    for suffix in [".txt.gz", ".csv.gz", ".tsv.gz"]:
        if name.endswith(suffix):
            return name[:-len(suffix)]

    return os.path.splitext(name)[0]


def parse_haplotype_file(path, autosomes, min_block_bp, strict=True):
    """
    Returns:
        sample_name, dict: chrom -> list of homolog block lists

    For each autosome, the expected structure is:
        chrom call line for homolog/copy 1
        gap line
        chrom call line for homolog/copy 2
        gap line

    The script preserves order and calls these "top" and "bottom" later.
    """

    blocks_by_chrom = defaultdict(list)
    sample_name = None

    with open(path, newline="") as handle:
        reader = csv.reader(handle)

        for lineno, row in enumerate(reader, start=1):
            if not row:
                continue

            first = row[0].strip()

            # Pull sample name from:
            # title,top,"CC001-UncM4363_NYGC"
            if first == "title" and len(row) >= 3 and row[1].strip() == "top":
                sample_name = row[2].strip().strip('"')
                continue

            # Skip headers, gap lines, chrX/chrY/chrM, etc.
            if first not in autosomes:
                continue

            chrom = first

            # Expected call line:
            # chr1,,B,1,45115373,E,43548869,138375475,...
            payload = row[2:]

            if len(payload) == 0 or len(payload) % 3 != 0:
                warn_or_fail(
                    "{}:{} malformed call line; expected hap,start,end triples after first two fields".format(
                        path, lineno
                    ),
                    strict=strict,
                )
                if not strict:
                    continue

            blocks = []

            for i in range(0, len(payload), 3):
                hap = payload[i].strip()
                start_s = payload[i + 1].strip()
                end_s = payload[i + 2].strip()

                try:
                    start = int(start_s)
                    end = int(end_s)
                except ValueError:
                    warn_or_fail(
                        "{}:{} could not parse integer coordinates in triple: {}".format(
                            path, lineno, payload[i:i + 3]
                        ),
                        strict=strict,
                    )
                    if not strict:
                        continue

                if end < start:
                    warn_or_fail(
                        "{}:{} block has end < start: {}".format(
                            path, lineno, payload[i:i + 3]
                        ),
                        strict=strict,
                    )
                    if not strict:
                        continue

                # Coordinates are treated as 1-based, end-exclusive.
                # Length is therefore end - start.
                if end - start >= min_block_bp:
                    blocks.append(Block(chrom, start, end, hap))

            blocks_by_chrom[chrom].append(blocks)

    if sample_name is None:
        sample_name = fallback_sample_name(path)

    return sample_name, blocks_by_chrom


def merge_adjacent_blocks(blocks):
    """
    Merge directly adjacent intervals with the same haplotype call.
    Assumes blocks are already sorted and non-overlapping.
    """

    merged = []

    for block in blocks:
        if (
            merged
            and merged[-1].chrom == block.chrom
            and merged[-1].hap == block.hap
            and merged[-1].end == block.start
        ):
            prev = merged[-1]
            merged[-1] = Block(prev.chrom, prev.start, block.end, prev.hap)
        else:
            merged.append(block)

    return merged


def remove_conflicting_overlaps(blocks):
    """
    Splits a single homolog/copy into non-overlapping segments.

    Any segment covered by exactly one haplotype call is kept.
    Any segment covered by conflicting haplotype calls is discarded.

    If overlapping blocks have the same haplotype call, the segment is kept
    as that haplotype, since it is not an ambiguous call.
    """

    blocks = sorted(blocks, key=lambda b: (b.start, b.end, b.hap))

    if not blocks:
        return []

    chrom = blocks[0].chrom
    boundaries = sorted(set([b.start for b in blocks] + [b.end for b in blocks]))

    cleaned = []

    for start, end in zip(boundaries, boundaries[1:]):
        if end <= start:
            continue

        covering_haps = set()

        for block in blocks:
            # Because start/end are generated from all block boundaries,
            # each segment is either fully covered or not covered by a block.
            if block.start <= start and block.end >= end:
                covering_haps.add(block.hap)

        if len(covering_haps) == 1:
            hap = next(iter(covering_haps))
            cleaned.append(Block(chrom, start, end, hap))

        # len == 0: gap, discard
        # len > 1: conflicting overlap, discard

    return merge_adjacent_blocks(cleaned)


def merge_adjacent_pair_rows(rows):
    """
    Merge adjacent final rows if both haplotype calls are unchanged.
    Row format:
        sample, chrom, start, end, top_hap, bottom_hap, source_file
    """

    merged = []

    for row in rows:
        sample, chrom, start, end, top_hap, bottom_hap, source_file = row

        if merged:
            prev = merged[-1]
            (
                p_sample,
                p_chrom,
                p_start,
                p_end,
                p_top_hap,
                p_bottom_hap,
                p_source_file,
            ) = prev

            if (
                p_sample == sample
                and p_chrom == chrom
                and p_end == start
                and p_top_hap == top_hap
                and p_bottom_hap == bottom_hap
                and p_source_file == source_file
            ):
                merged[-1] = (
                    p_sample,
                    p_chrom,
                    p_start,
                    end,
                    p_top_hap,
                    p_bottom_hap,
                    p_source_file,
                )
                continue

        merged.append(row)

    return merged


def pair_homolog_blocks(sample, chrom, top_blocks, bottom_blocks, source_file, min_final_bp):
    """
    Create matching top/bottom intervals.

    A final interval is kept only when both homologs have exactly one
    haplotype call covering that segment.
    """

    all_blocks = top_blocks + bottom_blocks

    if not all_blocks:
        return []

    boundaries = sorted(set([b.start for b in all_blocks] + [b.end for b in all_blocks]))
    rows = []

    for start, end in zip(boundaries, boundaries[1:]):
        if end <= start:
            continue

        top_haps = set()
        bottom_haps = set()

        for block in top_blocks:
            if block.start <= start and block.end >= end:
                top_haps.add(block.hap)

        for block in bottom_blocks:
            if block.start <= start and block.end >= end:
                bottom_haps.add(block.hap)

        # Keep only fully diploid-called segments.
        if len(top_haps) == 1 and len(bottom_haps) == 1:
            if end - start >= min_final_bp:
                rows.append(
                    (
                        sample,
                        chrom,
                        start,
                        end,
                        next(iter(top_haps)),
                        next(iter(bottom_haps)),
                        source_file,
                    )
                )

    return merge_adjacent_pair_rows(rows)


def process_file(path, autosomes, min_block_bp, min_final_bp, strict=True):
    sample, blocks_by_chrom = parse_haplotype_file(
        path=path,
        autosomes=autosomes,
        min_block_bp=min_block_bp,
        strict=strict,
    )

    output_rows = []

    for chrom in sorted(blocks_by_chrom, key=chrom_sort_key):
        homologs = blocks_by_chrom[chrom]

        if len(homologs) != 2:
            warn_or_fail(
                "{}: expected exactly 2 call lines for {}, found {}".format(
                    path, chrom, len(homologs)
                ),
                strict=strict,
            )
            if not strict:
                continue

        top_raw = homologs[0]
        bottom_raw = homologs[1]

        top_clean = remove_conflicting_overlaps(top_raw)
        bottom_clean = remove_conflicting_overlaps(bottom_raw)

        paired = pair_homolog_blocks(
            sample=sample,
            chrom=chrom,
            top_blocks=top_clean,
            bottom_blocks=bottom_clean,
            source_file=os.path.basename(path),
            min_final_bp=min_final_bp,
        )

        output_rows.extend(paired)

    return output_rows


def main():
    parser = argparse.ArgumentParser(
        description="Parse diploid haplotype block call files into paired, non-overlapping TSV intervals."
    )

    parser.add_argument(
        "inputs",
        nargs="+",
        help="Input haplotype block call file(s).",
    )

    parser.add_argument(
        "-o",
        "--output",
        default="-",
        help="Output TSV. Default: stdout.",
    )

    parser.add_argument(
        "--min-block-bp",
        type=int,
        default=1000000,
        help="Discard raw blocks smaller than this many bp before overlap cleanup. Default: 1000000.",
    )

    parser.add_argument(
        "--min-final-bp",
        type=int,
        default=0,
        help=(
            "Optionally discard final paired intervals smaller than this many bp "
            "after trimming/splitting. Default: 0."
        ),
    )

    parser.add_argument(
        "--autosomes",
        default="mouse",
        help=(
            "Autosomes to include. Use 'mouse' for chr1-chr19, or provide a comma-separated list. "
            "Default: mouse."
        ),
    )

    parser.add_argument(
        "--lenient",
        action="store_true",
        help="Warn and skip malformed records instead of stopping with an error.",
    )

    parser.add_argument(
        "--no-header",
        action="store_true",
        help="Do not print the output header.",
    )

    args = parser.parse_args()

    autosomes = parse_autosomes(args.autosomes)
    strict = not args.lenient

    if args.output == "-":
        out = sys.stdout
        close_out = False
    else:
        out = open(args.output, "w", newline="")
        close_out = True

    try:
        writer = csv.writer(out, delimiter="\t", lineterminator="\n")

        if not args.no_header:
            writer.writerow(
                [
                    "sample",
                    "chrom",
                    "start_1based",
                    "end_exclusive",
                    "end_inclusive",
                    "top_haplotype",
                    "bottom_haplotype",
                    "length_bp",
                    "vcf_region",
                    "source_file",
                ]
            )

        for path in args.inputs:
            rows = process_file(
                path=path,
                autosomes=autosomes,
                min_block_bp=args.min_block_bp,
                min_final_bp=args.min_final_bp,
                strict=strict,
            )

            for sample, chrom, start, end, top_hap, bottom_hap, source_file in rows:
                end_inclusive = end - 1
                length_bp = end - start
                vcf_region = "{}:{}-{}".format(chrom, start, end_inclusive)

                writer.writerow(
                    [
                        sample,
                        chrom,
                        start,
                        end,
                        end_inclusive,
                        top_hap,
                        bottom_hap,
                        length_bp,
                        vcf_region,
                        source_file,
                    ]
                )

    finally:
        if close_out:
            out.close()


if __name__ == "__main__":
    main()
