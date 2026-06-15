import sys


def read_fasta(filename):
    with open(filename, 'r') as file:

        sequences = {}

        chrom_name = ''

        sequence = ''

        for line in file:

            if line.startswith('>'):

                if chrom_name:
                    sequences[chrom_name] = sequence

                chrom_name = line[1:].strip()

                sequence = ''

            else:

                sequence += line.strip().upper()

        if chrom_name:
            sequences[chrom_name] = sequence

    return sequences


def find_gaps(sequence):
    gaps = []

    in_gap = False

    start = 0

    for i, base in enumerate(sequence):

        if (base == 'N'):

            if not in_gap:
                start = i

                in_gap = True

        else:

            if in_gap:
                gaps.append((start, i))

                in_gap = False

    if in_gap:
        gaps.append((start, len(sequence)))

    return gaps


def write_bed(gaps, chrom_name, output):
    with open(output, 'a') as f:  # Appending to the file instead of overwriting

        for start, end in gaps:
            gap_size = end - start

            f.write(f"{chrom_name}\t{start + 1}\t{end}\t{gap_size}\n")  # Adjust start by +1


def count_gap_bases_and_blocks(sequence):
    in_gap = False

    total_gap_bases = 0

    gap_blocks = 0

    for base in sequence:

        if base == 'N':

            if not in_gap:
                in_gap = True

                gap_blocks += 1

            total_gap_bases += 1

        else:

            in_gap = False

    return total_gap_bases, gap_blocks


def write_sequence_info(info, output_file):
    print(f"Writing sequence info to {output_file}")

    total_bp = 0

    total_gap_blocks = 0

    total_gap_bp = 0

    with open(output_file, 'w') as f:
        # Write header line

        f.write("chrom_name\ttotal_bp\ttotal_gap_blocks\tgap_bp\n")

        for chrom_name, (total_bp_chr, gap_blocks, gap_bp) in info.items():
            f.write(f"{chrom_name}\t{total_bp_chr}\t{gap_blocks}\t{gap_bp}\n")

            total_bp += total_bp_chr

            total_gap_blocks += gap_blocks

            total_gap_bp += gap_bp

        # Write totals line

        f.write(f"TOTAL\t{total_bp}\t{total_gap_blocks}\t{total_gap_bp}\n")


def extract_gaps(input_fasta, output_bed, output_info):
    sequences = read_fasta(input_fasta)

    open(output_bed, 'w').close()  # Clear the contents of the output file

    print("Calculating gaps and writing to BED file...")

    sequence_info = {}

    for chrom_name, sequence in sequences.items():
        gaps = find_gaps(sequence)

        write_bed(gaps, chrom_name, output_bed)

        total_bp = len(sequence)

        gap_bp, gap_blocks = count_gap_bases_and_blocks(sequence)

        sequence_info[chrom_name] = (total_bp, gap_blocks, gap_bp)

    print("Writing sequence information...")

    write_sequence_info(sequence_info, output_info)


if __name__ == "__main__":

    if len(sys.argv) != 4:

        print("Usage: python script.py input.fasta output_gaps.bed output_info.txt")

    else:

        input_fasta = sys.argv[1]

        output_bed = sys.argv[2]

        output_info = sys.argv[3]

        print(f"Processing input FASTA: {input_fasta}")

        extract_gaps(input_fasta, output_bed, output_info)

        print("Processing complete.")