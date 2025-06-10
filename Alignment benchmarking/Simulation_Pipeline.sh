#!/bin/bash
# Usage:
#   bash Simulation_Pipeline.sh -n <cores> -o <output_dir> -l <library_name> -g <input_genome> -d <read_depth>
#
#   -n <cores>        Number of CPU cores to use (optional, default: 1)
#   -o <output_dir>   Output directory (optional, default: ./)
#   -l <library_name> Library name (optional, default: based on genome name)
#   -g <input_genome> Genome to simulate (required)
#   -d <read_depth>   Read depth to simulate (required)
#
# Notes:
#
#   - The simulated FASTQ files are compressed to .gz format.
#   - The output directory is structured as:
#         <output_dir>/<read_depth>_depth_library/<library_name>

# Default values
cores=1
output_dir="."
library_name=""
input_genome=""
seq_depth=""

# Parse input arguments
while getopts n:o:l:g:d: flag; do
    case "${flag}" in
        n) cores="${OPTARG}" ;;
        o) output_dir="${OPTARG}" ;;
        l) library_name="${OPTARG}" ;;
        g) input_genome="${OPTARG}" ;;
        d) seq_depth="${OPTARG}" ;;
        *) echo "Error: Invalid option -${OPTARG}" >&2
           exit 1 ;;
    esac
done

# Check if the required parameters are provided
if [ -z "$input_genome" ]; then
    echo "Error: Please provide the input genome using the -g option." >&2
    exit 1
fi

if [ -z "$seq_depth" ]; then
    echo "Error: Please provide the read depth using the -d option." >&2
    exit 1
fi

if [ ! -f "$input_genome" ]; then
    echo "Error: Input genome file does not exist: $input_genome" >&2
    exit 1
fi

# Extract the genome name (removing .fa or .fasta extension)
genome_name=$(basename "$input_genome" .fa)
genome_name=$(basename "$genome_name" .fasta)

# Set default library name if not provided
if [ -z "$library_name" ]; then
    library_name="${genome_name}_library"
fi

# Create output directory structure:
library_dir="${output_dir}/${seq_depth}_depth_library_Child_Free/${library_name}"
mkdir -p "$library_dir"

# Print the configuration
echo "Starting simulation pipeline with the following parameters:"
echo "Number of cores: $cores"
echo "Output directory: $output_dir"
echo "Library directory: $library_dir"
echo "Input genome: $input_genome"
echo "Read depth: $seq_depth"

# Index the input genome (samtools will create/update the .fai file)
samtools faidx "$input_genome"

# Calculate total genome length from the .fai index (sum of 2nd column)
total_length=$(awk '{sum+=$2} END {print sum}' "${input_genome}.fai")
echo "Total genome length: $total_length"

# Set the read length (as used in the simulation)
read_length=100

# Calculate the number of read pairs using:
# N_pairs = (seq_depth * total_length) / (2 * read_length)
N_pairs=$(( seq_depth * total_length / (2 * read_length) ))
echo "Calculated number of read pairs: $N_pairs"

# Define output FASTQ file names (gzipped)
out_R1="${library_dir}/${genome_name}_R1.fastq.gz"
out_R2="${library_dir}/${genome_name}_R2.fastq.gz"

# Run the simulation with wgsim using process substitution to gzip the outputs on the fly
echo "Simulating reads with wgsim on the whole genome..."
wgsim -N "$N_pairs" -1 100 -2 100 -r 0.00 -R 0.00 -X 0.0 -e 0.00 -d 319 -s 85 -S 1 \
    "$input_genome" \
    >(gzip > "$out_R1") \
    >(gzip > "$out_R2")

echo "Simulation completed successfully."