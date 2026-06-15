#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 6 ]]; then
    echo "Usage: $0 <input_fasta> <output_dir> [read_length] [seq_depth] [insert_size] [insert_size_std_dev]" >&2
    exit 1
fi

input_fasta=$1
output_dir=$2
read_length=${3:-150}
seq_depth=${4:-15}
insert_size=${5:-303}
insert_size_std_dev=${6:-112}

if [[ ! -f "$input_fasta" ]]; then
    echo "ERROR: input fasta not found: $input_fasta" >&2
    exit 1
fi

sample_name=$(basename "$input_fasta" .fasta)

mkdir -p "$output_dir"

# Work in the output directory so final filenames are simple/predictable
cd "$output_dir"

echo "Sample: $sample_name"
echo "Input FASTA: $input_fasta"
echo "Output directory: $output_dir"
echo "Read length: $read_length"
echo "Sequencing depth: $seq_depth"
echo "Insert size: $insert_size"
echo "Insert size SD: $insert_size_std_dev"

# Ensure FASTA index exists
if [[ ! -f "${input_fasta}.fai" ]]; then
    echo "FASTA index not found; indexing with samtools faidx..."
    samtools faidx "$input_fasta"
fi

# Calculate total genome length from the .fai index (sum of 2nd column)
genome_length=$(awk '{sum+=$2} END {print sum}' "${input_fasta}.fai")
echo "Total genome length: $genome_length"

# Calculate number of read pairs
N_pairs=$(( seq_depth * genome_length / (2 * read_length) ))
echo "Calculated number of read pairs: $N_pairs"

# Define output file names
out_R1="${sample_name}_R1.fastq"
out_R2="${sample_name}_R2.fastq"

# Avoid silently overwriting existing outputs
if [[ -e "${out_R1}.gz" || -e "${out_R2}.gz" || -e "$out_R1" || -e "$out_R2" ]]; then
    echo "ERROR: output already exists for $sample_name in $output_dir" >&2
    exit 1
fi

echo "Simulating reads with wgsim..."
wgsim \
    -N "$N_pairs" \
    -1 "$read_length" \
    -2 "$read_length" \
    -r 0.00 \
    -R 0.00 \
    -X 0.0 \
    -e 0.00 \
    -d "$insert_size" \
    -s "$insert_size_std_dev" \
    -S 1 \
    "$input_fasta" \
    "$out_R1" \
    "$out_R2"

echo "Done."
echo "Outputs:"
echo "  ${output_dir}/${out_R1}.gz"
echo "  ${output_dir}/${out_R2}.gz"
