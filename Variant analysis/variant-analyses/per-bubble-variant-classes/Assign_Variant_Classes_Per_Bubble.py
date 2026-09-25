import argparse
import gzip
import sys
import re


def classify_variant(ref, alt):
    # Missing allele
    if alt == '.':
        return 'missing'
    ref_len = len(ref)
    alt_len = len(alt)
    diff = abs(alt_len - ref_len)
    # No net length change
    if diff == 0:
        # Single-base change
        if ref_len == 1:
            return 'SNV'
        # Multi-base substitution
        return 'MNV'
    # Net length change
    else:
        # Simple indel: one side allele length is 1
        if ref_len == 1 or alt_len == 1:
            return 'INDEL'
        # Composite: substitution plus indel
        return 'COMPOSITE'


def process_vcf(infile, outfile):
    header = [
        'CHROM', 'POS', 'ID', 'REF_LEN', 'ALT_LENS', 'NUM_ALTS',
        'REF_NS', 'ALT_NS', 'ALT_MISSING', 'LEN_DIFFS',
        'REF_LEN_GT1', 'VARIANT_CLASSES', 'SITE_LABEL', 'N_EQUIV'
    ]
    outfile.write('\t'.join(header) + '\n')

    open_func = gzip.open if infile.endswith('.gz') else open
    with open_func(infile, 'rt') as f:
        for line in f:
            if line.startswith('#'):
                continue
            fields = line.rstrip('\n').split('\t')
            chrom, pos, vid, ref, alt_field = (
                fields[0], fields[1], fields[2], fields[3], fields[4]
            )
            alt_alleles = alt_field.split(',')
            ref_len = len(ref)
            ref_ns = ref.upper().count('N')

            alt_lens = []
            alt_ns = []
            alt_missing = []
            len_diffs = []
            classes = []

            for alt in alt_alleles:
                length = 0 if alt == '.' else len(alt)
                alt_lensestr = str(length)
                alt_lens.append(alt_lensestr)

                ns = 0 if alt == '.' else alt.upper().count('N')
                alt_ns.append(str(ns))

                missing = (alt == '.')
                alt_missing.append(str(missing))

                diff = abs(length - ref_len)
                len_diffs.append(str(diff))

                cls = classify_variant(ref, alt)
                classes.append(cls)

            # Compute bitwise site label
            class2bit = {
                'SNV': 1,
                'INDEL': 2,
                'COMPOSITE': 4,
                'MNV': 8
            }
            site_label = 0
            for cls in set(classes):
                site_label |= class2bit.get(cls, 0)
            # GAP bit if any N in REF or ALTs
            if ref_ns > 0 or any(int(ns_str) > 0 for ns_str in alt_ns):
                site_label |= 16

            # N-equivalency test per ALT allele
            all_alleles = [ref] + alt_alleles
            n_equiv = []
            for alt in alt_alleles:
                if 'N' in alt.upper():
                    # escape then convert N-run to wildcard .*
                    esc = re.escape(alt.upper())
                    pattern = '^' + re.sub(r'N+', '.*', esc) + '$'
                    regex = re.compile(pattern)
                    match_found = False
                    for other in all_alleles:
                        if other == alt:
                            continue
                        if regex.match(other.upper()):
                            match_found = True
                            break
                    n_equiv.append(str(match_found))
                else:
                    n_equiv.append('NA')

            num_alts = len(alt_alleles)
            ref_len_gt1 = str(ref_len > 1)

            row = [
                chrom,
                pos,
                vid,
                str(ref_len),
                ','.join(alt_lens),
                str(num_alts),
                str(ref_ns),
                ','.join(alt_ns),
                ','.join(alt_missing),
                ','.join(len_diffs),
                ref_len_gt1,
                ','.join(classes),
                str(site_label),
                ','.join(n_equiv)
            ]
            outfile.write('\t'.join(row) + '\n')


def main():
    parser = argparse.ArgumentParser(
        description=(
            'Calculate per-site variant stats, classify SNV/MNV/INDEL/COMPOSITE, ' \
            'compute bitwise SITE_LABEL with GAP, and perform N-equivalency testing.'
        )
    )
    parser.add_argument('vcf', help='Input VCF (vcf or vcf.gz)')
    parser.add_argument(
        '-o', '--out', help='Output TSV (default stdout)', default='-'
    )
    args = parser.parse_args()

    out_handle = sys.stdout if args.out in ('-', 'stdout') else open(args.out, 'w')
    try:
        process_vcf(args.vcf, out_handle)
    finally:
        if out_handle is not sys.stdout:
            out_handle.close()

if __name__ == '__main__':
    main()