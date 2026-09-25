#!/usr/bin/env python3
"""
Split phased CC0* sample genotypes (e.g. 1|1) into two separate haplotype columns.
CC001 -> CC001.1 and CC001.2

Usage:
    python split_cc_haplotypes.py input.vcf output.vcf
    python split_cc_haplotypes.py input.vcf.gz output.vcf.gz
"""

import sys
import re
import gzip


def open_maybe_gz(path, mode):
    if path.endswith(".gz"):
        return gzip.open(path, mode + "t")
    return open(path, mode)


def split_cc_haplotypes(input_vcf, output_vcf):
    with open_maybe_gz(input_vcf, "r") as fin, open_maybe_gz(output_vcf, "w") as fout:
        cc_indices = []

        for line in fin:
            # Pass through meta-info lines unchanged
            if line.startswith('##'):
                fout.write(line)
                continue

            fields = line.rstrip('\n').split('\t')

            # Header line
            if line.startswith('#CHROM'):
                new_header = []
                for col in fields:
                    if re.match(r'CC\d+', col):
                        new_header.append(col + '.1')
                        new_header.append(col + '.2')
                    else:
                        new_header.append(col)
                fout.write('\t'.join(new_header) + '\n')

                # Record which columns are CC samples
                cc_indices = [i for i, col in enumerate(fields) if re.match(r'CC\d+', col)]
                continue

            # Data lines
            new_fields = []
            for i, val in enumerate(fields):
                if i in cc_indices:
                    # Split on | or /
                    parts = re.split(r'[|/]', val)
                    if len(parts) == 2:
                        new_fields.append(parts[0])
                        new_fields.append(parts[1])
                    else:
                        # Unphased or missing - duplicate as-is
                        new_fields.append(val)
                        new_fields.append(val)
                else:
                    new_fields.append(val)

            fout.write('\t'.join(new_fields) + '\n')

    print(f"Done. Written to {output_vcf}")


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python split_cc_haplotypes.py input.vcf[.gz] output.vcf[.gz]")
        sys.exit(1)

    split_cc_haplotypes(sys.argv[1], sys.argv[2])