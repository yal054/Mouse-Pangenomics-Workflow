#!/bin/bash
# Custom_Counting.sh
# Usage: Custom_Counting.sh -s flagstat_file -b input.bam -o output_dir -t threads
# Note: The sample name is extracted from the bam file name.

# Default threads value
threads=1

# Parse command-line options
while getopts "s:b:o:t:" opt; do
    case $opt in
        s)
            flagstat_file="$OPTARG"  # Flagstat file provided with -s
            ;;
        b)
            bam_file="$OPTARG"       # BAM file provided with -b
            ;;
        o)
            output_dir="$OPTARG"     # Output directory provided with -o
            ;;
        t)
            threads="$OPTARG"        # Number of threads provided with -t
            ;;
        *)
            echo "Usage: $0 -s flagstat_file -b input.bam -o output_dir -t threads"
            exit 1
            ;;
    esac
done

# Check if required parameters are provided
if [ -z "$flagstat_file" ] || [ -z "$bam_file" ] || [ -z "$output_dir" ]; then
    echo "Usage: $0 -s flagstat_file -b input.bam -o output_dir -t threads"
    exit 1
fi

# Check if flagstat file exists
if [ ! -f "$flagstat_file" ]; then
    echo "Error: Flagstat file $flagstat_file not found!"
    exit 1
fi

# Check if BAM file exists
if [ ! -f "$bam_file" ]; then
    echo "Error: BAM file $bam_file not found!"
    exit 1
fi

# Extract sample name from BAM file (remove path and .bam extension)
sample=$(basename "$bam_file")
sample="${sample%.bam}"

# Read primary (total) reads from the flagstat file (line 2, first number)
total_reads=$(sed -n '2p' "$flagstat_file" | awk '{print $1}')

# Mapped reads (line 8, first number)
mapped_reads=$(sed -n '8p' "$flagstat_file" | awk '{print $1}')

# Read properly paired reads from the flagstat file (line 12, first number)
properly_paired_reads=$(sed -n '12p' "$flagstat_file" | awk '{print $1}')

# Process the BAM file in one pass using samtools multithreading.
#  Using - F 2304 to exclude secondary and supplementary alignments.
# Use awk to count:
# - MAPQ = 60 reads (column 5 equals 60)
# - Gapless reads (CIGAR string in column 6 does not contain I or D)
# - Perfect reads (contain the NM:i:0 tag)

#Archive the original code
#read mapq60 gapless perfect < <(samtools view -F 2304 -@ "$threads" "$bam_file" | \
#awk '{
#    if($5==60) mapq60++;
#    if($6 !~ /[ID]/) gapless++;
#    if($0 ~ /NM:i:0/) perfect++;
#} END {
#    print mapq60, gapless, perfect
#}')

#New code
stats=$(samtools view -F 2308 -@ "$threads" "$bam_file" | \
awk 'BEGIN{mapq60=0; gapless=0; perfect=0}
{
    if($5==60) mapq60++;
    if($6 !~ /[ID]/) gapless++;
    if($0 ~ /NM:i:0/) perfect++;
}
END {
    print mapq60, gapless, perfect
}')

mapq60=$(echo "$stats" | awk '{print $1}')
gapless=$(echo "$stats" | awk '{print $2}')
perfect=$(echo "$stats" | awk '{print $3}')

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Define the output file name
output_file="${output_dir}/${sample}.custom_stats_shell.summary.txt"

# Write the results to the output file
cat <<EOF > "$output_file"
Sample: $sample
Total primary reads (from flagstat, line 2): $total_reads
Mapped reads (from flagstat, line 8): $mapped_reads
Properly paired reads (from flagstat, line 12): $properly_paired_reads

Samtools view filtering results from $bam_file using $threads thread(s):
MAPQ = 60 reads: $mapq60
Gapless reads: $gapless
Perfect reads (NM:i:0): $perfect
EOF

echo "Summary written to $output_file"