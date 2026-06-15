#!/bin/bash

set -eou pipefail

# Default threads value
threads=1

# Parse command-line options
while getopts "b:t:" opt; do
    case $opt in
        b)
            bam_file="$OPTARG"       # BAM file provided with -b
            ;;
        t)
            threads="$OPTARG"        # Number of threads provided with -t
            ;;
        *)
            echo "Usage: $0 -b input.bam -t threads"
            exit 1
            ;;
    esac
done

# Check if required parameters are provided
if [ -z "$bam_file" ]; then
    echo "Usage: $0 -b input.bam -t threads"
    exit 1
fi

# Check if BAM file exists
if [ ! -f "$bam_file" ]; then
    echo "Error: BAM file $bam_file not found!"
    exit 1
fi



OUTPUT_PREFIX=${bam_file%%.bam}
flagstat_file=$OUTPUT_PREFIX.flagstats
output_file=$OUTPUT_PREFIX.custom-metrics.txt

# run flagstat
samtools flagstat -@ $threads $bam_file > $flagstat_file



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


# Write the results to the output file
cat <<EOF > "$output_file"
Total primary reads (from flagstat, line 2): $total_reads
Mapped reads (from flagstat, line 8): $mapped_reads
Properly paired reads (from flagstat, line 12): $properly_paired_reads

Samtools view filtering results from $bam_file using $threads thread(s):
MAPQ = 60 reads: $mapq60
Gapless reads: $gapless
Perfect reads (NM:i:0): $perfect
EOF

echo "Summary written to $output_file"
