#!/usr/bin/env python3
"""
Convert haploid VCF genotypes to homozygous diploid.

Reads VCF from stdin, writes to stdout.
For each sample, if the GT field is a single allele (no | or /):
  - missing (.)  -> 0|0  (in graph deconstruct VCFs, missing means the assembly
                           follows the reference path, so ref/ref is correct)
  - ref   (0)    -> 0|0
  - alt   (1)    -> 1|1

Usage:
    bcftools view -s FOUNDERS ref.vcf.gz | python3 convert_haploid_to_diploid_vcf.py | bgzip > ref_diploid.vcf.gz
"""

import sys


def main():
    for line in sys.stdin:
        if line.startswith('#'):
            sys.stdout.write(line)
            continue

        fields = line.rstrip('\n').split('\t')

        # Find GT index in FORMAT field (fields[8])
        fmt = fields[8].split(':')
        try:
            gt_idx = fmt.index('GT')
        except ValueError:
            # No GT field: pass through unchanged
            sys.stdout.write(line)
            continue

        for i in range(9, len(fields)):
            subfields = fields[i].split(':')
            gt = subfields[gt_idx]

            # If haploid (no | or / separator), convert to diploid:
            # missing (.) -> 0|0 (ref/ref); ref/alt -> homozygous diploid
            if '|' not in gt and '/' not in gt:
                if gt == '.':
                    subfields[gt_idx] = '0|0'
                else:
                    subfields[gt_idx] = gt + '|' + gt

            fields[i] = ':'.join(subfields)

        sys.stdout.write('\t'.join(fields) + '\n')


if __name__ == '__main__':
    main()
