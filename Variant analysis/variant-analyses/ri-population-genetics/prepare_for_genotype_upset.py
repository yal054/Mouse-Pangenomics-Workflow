import csv
import argparse


def process_file(infile, outfile):
    with open(infile, 'r') as fin, open(outfile, 'w', newline='') as fout:
        # Input is tab-delimited.
        reader = csv.DictReader(fin, delimiter='\t')
        # First two columns are CHROM and POS; the rest are sample names.
        samples = reader.fieldnames[2:]

        # Output columns: CHROM, POS, GT, then one column per sample.
        fieldnames = ['CHROM', 'POS', 'GT'] + samples
        writer = csv.DictWriter(fout, fieldnames=fieldnames, delimiter='\t')
        writer.writeheader()

        for row in reader:
            chrom = row['CHROM']
            pos = row['POS']

            # Build a dictionary mapping sample -> genotype (as integer) or None if missing.
            sample_genotypes = {}
            for sample in samples:
                val = row[sample].strip()
                if val == '.' or val == '':
                    sample_genotypes[sample] = None
                else:
                    try:
                        sample_genotypes[sample] = int(val)
                    except ValueError:
                        sample_genotypes[sample] = None

            # Gather unique genotype indexes from observed (non-missing) values.
            unique_gts = {g for g in sample_genotypes.values() if g is not None}
            # Always include 0 (reference) even if no sample explicitly has 0.
            unique_gts.add(0)

            # For each genotype index, create an output row.
            for gt in sorted(unique_gts):
                out_row = {'CHROM': chrom, 'POS': pos, 'GT': gt}
                for sample in samples:
                    # Output 1 only if the sample's genotype is not missing and equals gt; otherwise 0.
                    out_row[sample] = 1 if sample_genotypes[sample] is not None and sample_genotypes[
                        sample] == gt else 0
                writer.writerow(out_row)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Process a variant genotype file into per-genotype rows for an UpSet plot."
    )
    parser.add_argument('-i', '--infile', required=True, help="Input file (e.g., variant_genotypes.txt)")
    parser.add_argument('-o', '--outfile', required=True, help="Output file (processed format)")
    args = parser.parse_args()
    process_file(args.infile, args.outfile)
