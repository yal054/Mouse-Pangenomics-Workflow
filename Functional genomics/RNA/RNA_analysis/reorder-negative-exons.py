#!/usr/bin/env python3

import argparse
import sys


def extract_quoted_attr(attr_text, key):
    needle = key + ' "'
    i = attr_text.find(needle)
    if i == -1:
        return None
    i += len(needle)
    j = attr_text.find('"', i)
    if j == -1:
        return None
    return attr_text[i:j]


def parse_gtf_line(line, line_no, need_exon_number=False):
    stripped = line.rstrip("\n")

    if not stripped or stripped.startswith("#"):
        return {
            "kind": "raw",
            "raw": line,
            "line_no": line_no,
        }

    fields = stripped.split("\t")
    if len(fields) != 9:
        raise ValueError(f"Line {line_no}: expected 9 tab-delimited columns, found {len(fields)}")

    feature = fields[2]
    start = int(fields[3])
    end = int(fields[4])
    strand = fields[6]
    attrs = fields[8]

    transcript_id = extract_quoted_attr(attrs, "transcript_id")

    exon_number = None
    if need_exon_number and feature == "exon":
        exon_number_text = extract_quoted_attr(attrs, "exon_number")
        if exon_number_text is not None:
            try:
                exon_number = int(exon_number_text)
            except ValueError:
                exon_number = exon_number_text

    return {
        "kind": "gtf",
        "raw": line,
        "line_no": line_no,
        "feature": feature,
        "start": start,
        "end": end,
        "strand": strand,
        "transcript_id": transcript_id,
        "exon_number": exon_number,
    }


def is_non_decreasing(pairs):
    return all(pairs[i] <= pairs[i + 1] for i in range(len(pairs) - 1))


def is_strictly_increasing(nums):
    return all(nums[i] < nums[i + 1] for i in range(len(nums) - 1))


def is_strictly_decreasing(nums):
    return all(nums[i] > nums[i + 1] for i in range(len(nums) - 1))


def fail_or_warn(msg, args, counters):
    if args.warn_only:
        print("WARNING:", msg, file=sys.stderr)
        counters["warnings"] += 1
    else:
        raise SystemExit("ERROR: " + msg)


def process_group(group, out_handle, args, counters):
    if not group:
        return

    counters["groups"] += 1

    exon_indices = [i for i, rec in enumerate(group) if rec["feature"] == "exon"]
    exons = [group[i] for i in exon_indices]

    if not exons:
        for rec in group:
            out_handle.write(rec["raw"])
        return

    strand_values = {rec["strand"] for rec in exons if rec["strand"] in {"+", "-"}}
    transcript_strands = {rec["strand"] for rec in group if rec["feature"] == "transcript" and rec["strand"] in {"+", "-"}}

    strand = None
    if transcript_strands:
        if len(transcript_strands) > 1:
            fail_or_warn(
                f"Transcript block ending at line {group[-1]['line_no']} has multiple transcript strands: {sorted(transcript_strands)}",
                args,
                counters,
            )
        strand = next(iter(transcript_strands))

    if strand is None and strand_values:
        if len(strand_values) > 1:
            fail_or_warn(
                f"Transcript block ending at line {group[-1]['line_no']} has multiple exon strands: {sorted(strand_values)}",
                args,
                counters,
            )
        strand = next(iter(strand_values))

    if args.check_strand:
        if len(strand_values) > 1:
            fail_or_warn(
                f"Transcript {group[0]['transcript_id']} has mixed exon strands: {sorted(strand_values)}",
                args,
                counters,
            )
        if transcript_strands and strand_values and transcript_strands != strand_values:
            fail_or_warn(
                f"Transcript {group[0]['transcript_id']} has transcript/exon strand mismatch: transcript={sorted(transcript_strands)}, exon={sorted(strand_values)}",
                args,
                counters,
            )

    coord_pairs = [(rec["start"], rec["end"]) for rec in exons]

    if args.check_coordinates or args.strict:
        if strand == "-":
            # Current input is expected to be genomic ascending before we reverse it.
            if not is_non_decreasing(coord_pairs):
                fail_or_warn(
                    f"Negative-strand transcript {group[0]['transcript_id']} is not already in ascending genomic exon order before reversal",
                    args,
                    counters,
                )
        elif strand == "+" and args.check_positive:
            if not is_non_decreasing(coord_pairs):
                fail_or_warn(
                    f"Positive-strand transcript {group[0]['transcript_id']} is not in ascending genomic exon order",
                    args,
                    counters,
                )

    if args.check_exon_number or args.strict:
        exon_numbers = [rec["exon_number"] for rec in exons]

        if any(x is None for x in exon_numbers):
            fail_or_warn(
                f"Transcript {group[0]['transcript_id']} is missing exon_number on at least one exon",
                args,
                counters,
            )
        elif not all(isinstance(x, int) for x in exon_numbers):
            fail_or_warn(
                f"Transcript {group[0]['transcript_id']} has non-integer exon_number values: {exon_numbers}",
                args,
                counters,
            )
        else:
            if strand == "-":
                # In the current input, negative-strand exon_number is expected to decrease
                # as coordinates increase.
                if not is_strictly_decreasing(exon_numbers):
                    fail_or_warn(
                        f"Negative-strand transcript {group[0]['transcript_id']} does not have decreasing exon_number values in input order: {exon_numbers}",
                        args,
                        counters,
                    )
            elif strand == "+" and args.check_positive:
                if not is_strictly_increasing(exon_numbers):
                    fail_or_warn(
                        f"Positive-strand transcript {group[0]['transcript_id']} does not have increasing exon_number values: {exon_numbers}",
                        args,
                        counters,
                    )

            if args.strict:
                expected = list(range(1, len(exon_numbers) + 1))
                if sorted(exon_numbers) != expected:
                    fail_or_warn(
                        f"Transcript {group[0]['transcript_id']} has exon_number values that are not exactly 1..N: {exon_numbers}",
                        args,
                        counters,
                    )

    # Reverse only exon entries for negative-strand transcripts.
    if strand == "-" and len(exon_indices) > 1:
        reordered = list(group)
        reversed_exons = list(reversed(exons))
        for idx, exon_rec in zip(exon_indices, reversed_exons):
            reordered[idx] = exon_rec

        for rec in reordered:
            out_handle.write(rec["raw"])

        counters["negative_transcripts_reordered"] += 1
        counters["exons_reordered"] += len(exons)
    else:
        for rec in group:
            out_handle.write(rec["raw"])


parser = argparse.ArgumentParser(
    description="Reverse exon order for negative-strand transcript blocks in a GTF, streaming one transcript block at a time."
)
parser.add_argument("input_gtf", help="Input GTF")
parser.add_argument("output_gtf", help="Output GTF")

parser.add_argument(
    "--check-exon-number",
    action="store_true",
    help="Check that exon_number values match the expected order within each transcript block",
)
parser.add_argument(
    "--check-coordinates",
    action="store_true",
    help="Check exon coordinate ordering within each transcript block",
)
parser.add_argument(
    "--check-positive",
    action="store_true",
    help="Also validate positive-strand exon ordering",
)
parser.add_argument(
    "--check-strand",
    action="store_true",
    help="Check for mixed or inconsistent strand values within a transcript block",
)
parser.add_argument(
    "--check-global-contiguity",
    action="store_true",
    help="Check that a transcript_id never reappears later in the file (uses extra memory for a set of seen IDs)",
)
parser.add_argument(
    "--strict",
    action="store_true",
    help="Turn on stronger validation (coordinates, exon_number, strand)",
)
parser.add_argument(
    "--warn-only",
    action="store_true",
    help="Print validation problems as warnings and continue instead of exiting",
)
parser.add_argument(
    "--stats",
    action="store_true",
    help="Print a small summary to stderr at the end",
)

args = parser.parse_args()

if args.strict:
    args.check_coordinates = True
    args.check_exon_number = True
    args.check_strand = True

need_exon_number = args.check_exon_number or args.strict

counters = {
    "groups": 0,
    "negative_transcripts_reordered": 0,
    "exons_reordered": 0,
    "warnings": 0,
}

seen_transcript_ids = set()
current_transcript_id = None
current_group = []

with open(args.input_gtf, "r") as infile, open(args.output_gtf, "w") as outfile:
    for line_no, line in enumerate(infile, start=1):
        rec = parse_gtf_line(line, line_no, need_exon_number=need_exon_number)

        if rec["kind"] == "raw":
            if current_group:
                process_group(current_group, outfile, args, counters)
                if args.check_global_contiguity and current_transcript_id is not None:
                    seen_transcript_ids.add(current_transcript_id)
                current_group = []
                current_transcript_id = None
            outfile.write(line)
            continue

        transcript_id = rec["transcript_id"]

        # Lines without transcript_id are passed through unchanged and force a flush
        # of any current transcript block.
        if transcript_id is None:
            if current_group:
                process_group(current_group, outfile, args, counters)
                if args.check_global_contiguity and current_transcript_id is not None:
                    seen_transcript_ids.add(current_transcript_id)
                current_group = []
                current_transcript_id = None
            outfile.write(line)
            continue

        if current_transcript_id is None:
            if args.check_global_contiguity and transcript_id in seen_transcript_ids:
                fail_or_warn(
                    f"transcript_id {transcript_id} reappears later in the file; block is not globally contiguous (line {line_no})",
                    args,
                    counters,
                )
            current_transcript_id = transcript_id
            current_group = [rec]
        elif transcript_id == current_transcript_id:
            current_group.append(rec)
        else:
            process_group(current_group, outfile, args, counters)
            if args.check_global_contiguity and current_transcript_id is not None:
                seen_transcript_ids.add(current_transcript_id)

            if args.check_global_contiguity and transcript_id in seen_transcript_ids:
                fail_or_warn(
                    f"transcript_id {transcript_id} reappears later in the file; block is not globally contiguous (line {line_no})",
                    args,
                    counters,
                )

            current_transcript_id = transcript_id
            current_group = [rec]

    if current_group:
        process_group(current_group, outfile, args, counters)

if args.stats:
    print(f"Transcript blocks processed:      {counters['groups']}", file=sys.stderr)
    print(f"Negative transcripts reordered:  {counters['negative_transcripts_reordered']}", file=sys.stderr)
    print(f"Exon lines reordered:            {counters['exons_reordered']}", file=sys.stderr)
    print(f"Warnings:                        {counters['warnings']}", file=sys.stderr)
