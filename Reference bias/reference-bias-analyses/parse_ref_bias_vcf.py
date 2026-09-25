#!/usr/bin/env python3
import argparse
import gzip
import sys


def parse_vcf(input_file, output_file, exclude_no_alt=False):
    # Open input file (support for gzipped files)
    if input_file.endswith('.gz'):
        fin = gzip.open(input_file, 'rt')
    else:
        fin = open(input_file, 'r')

    with fin as f, open(output_file, 'w') as fout:
        # Write header line with new allele fraction column
        fout.write(
            "chrom\tstart\tend\tref\talt\tlen_diff\tunfiltered_DP\tfiltered_DP\tallele_depth_1\tallele_depth_2\tallele_fraction\n")
        for line in f:
            # Skip header lines
            if line.startswith('#'):
                continue

            fields = line.strip().split('\t')
            chrom = fields[0]
            pos = int(fields[1])
            ref = fields[3]
            alt = fields[4]

            # Skip records where ALT contains "<*>" only if --exclude-no-alt was given
            if "<*>" in alt and exclude_no_alt:
                continue

            info = fields[7]
            format_field = fields[8]
            sample_field = fields[9]

            # Parse INFO field to get unfiltered depth (DP)
            info_dict = {}
            for entry in info.split(';'):
                if '=' in entry:
                    key, value = entry.split('=', 1)
                    info_dict[key] = value
                else:
                    info_dict[entry] = True
            unfiltered_depth = info_dict.get('DP', 'NA')

            # Parse FORMAT and sample field to get filtered depth (DP) and allele depth (AD)
            format_keys = format_field.split(':')
            sample_values = sample_field.split(':')
            format_dict = dict(zip(format_keys, sample_values))
            filtered_depth = format_dict.get('DP', 'NA')
            allele_depth_value = format_dict.get('AD', 'NA')

            # Split allele_depth_value into two columns, with special handling for <*> ref-only cases
            if allele_depth_value == 'NA':
                # if this is a <*> record (and we're keeping them) but no AD is present,
                # treat all filtered DP as ref-support
                if "<*>" in alt and not exclude_no_alt and filtered_depth != 'NA':
                    ad1 = int(filtered_depth)
                    ad2 = 0
                    allele_fraction = f"{ad1 / (ad1 + ad2):.4f}"
                else:
                    ad1 = 'NA'
                    ad2 = 'NA'
                    allele_fraction = 'NA'
            else:
                ad_split = allele_depth_value.split(',')
                if len(ad_split) == 2:
                    try:
                        ad1 = int(ad_split[0])
                        ad2 = int(ad_split[1])
                    except ValueError:
                        print(
                            f"Warning: record at {chrom}:{pos} has non-integer allele depths: {allele_depth_value}. Skipping.",
                            file=sys.stderr)
                        continue
                elif len(ad_split) == 3:
                    print(f"Warning: record at {chrom}:{pos} has 3 allele depths: {allele_depth_value}. Skipping.",
                          file=sys.stderr)
                    continue
                else:
                    print(
                        f"Warning: record at {chrom}:{pos} does not have exactly 2 allele depths: {allele_depth_value}. Skipping.",
                        file=sys.stderr)
                    continue

                # Calculate allele fraction, checking for division by zero
                total = ad1 + ad2
                if total == 0:
                    allele_fraction = "NA"
                else:
                    allele_fraction = f"{ad1 / total:.4f}"

            # Convert VCF coordinate (1-based) to BED (0-based start, end = start + len(ref))
            start = pos - 1
            end = start + len(ref)

            # Calculate length difference between ALT and REF alleles
            len_diff = len(alt) - len(ref)

            # Write the BED entry with all required columns
            fout.write(
                f"{chrom}\t{start}\t{end}\t{ref}\t{alt}\t{len_diff}\t{unfiltered_depth}\t{filtered_depth}\t{ad1}\t{ad2}\t{allele_fraction}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Parse a VCF file to generate a BED file entry for each site of variation. "
                    "The output includes unfiltered depth (INFO:DP), filtered depth (sample DP), "
                    "allele depths (sample AD split into two columns), the ref and alt alleles, "
                    "the length difference between them, and the allele fraction (allele_depth_1 / (allele_depth_1 + allele_depth_2)). "
                    "Lines with ALT containing '<*>' are skipped, and records with 3 allele depths produce a warning and are omitted."
    )
    parser.add_argument("-i", "--input", required=True,
                        help="Input VCF file (plain text or gzipped with .gz extension)")
    parser.add_argument("-o", "--output", required=True,
                        help="Output BED file")
    parser.add_argument("--exclude-no-alt", action="store_true", default=True,
                        help="Skip records where ALT contains '<*>' (otherwise keep them)")
    args = parser.parse_args()

    parse_vcf(args.input, args.output, args.exclude_no_alt)

if __name__ == "__main__":
    main()
