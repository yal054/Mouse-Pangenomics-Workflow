#!/bin/bash

# Create the header for the TSV file.
# Columns: sample, reference, Total_alignments, Total_aligned, Total_perfect, Total_gapless, Total_properly_paired, MapQ_60_reads
output_file="real.haploid.refv2.custom_stats.tsv"
echo -e "sample\treference\tTotal_alignments\tTotal_aligned\tTotal_perfect\tTotal_gapless\tTotal_properly_paired\tMapQ_60_reads" > "$output_file"

# Loop over each *.custom_stats_shell.summary.txt file in the current directory.
for file in *.custom_stats_shell.summary.txt; do
    # Extract the sample line and remove the "Sample: " prefix.
    sample_full=$(grep "^Sample:" "$file" | sed 's/Sample: //')

    # Extract the sample name: remove everything up to the first period, then remove the trailing "-query".
    # For example, "CC074-ref.CC074-query" becomes "CC074".
    sample=${sample_full#*.}
    sample=${sample%-query}

    # Hardcode the reference value to "Self".
    reference="mm10"

    # Extract Total_alignments from "Total primary reads (from flagstat, line 2):"
    Total_alignments=$(grep "Total primary reads (from flagstat, line 2):" "$file" | sed 's/Total primary reads (from flagstat, line 2): //')

    # Total_aligned from "Mapped reads (from flagstat, line 8):"
    Total_aligned=$(grep "Mapped reads (from flagstat, line 8):" "$file" | sed 's/Mapped reads (from flagstat, line 8): //')

    # Extract Total_perfect from "Perfect reads (NM:i:0):"
    Total_perfect=$(grep "Perfect reads (NM:i:0):" "$file" | sed 's/Perfect reads (NM:i:0): //')

    # Extract Total_gapless from "Gapless reads:"
    Total_gapless=$(grep "Gapless reads:" "$file" | sed 's/Gapless reads: //')

    # Extract Total_properly_paired from "Properly paired reads (from flagstat, line 12):"
    Total_properly_paired=$(grep "Properly paired reads (from flagstat, line 12):" "$file" | sed 's/Properly paired reads (from flagstat, line 12): //')

    # Extract MapQ_60_reads from "MAPQ = 60 reads:"
    MapQ_60_reads=$(grep "MAPQ = 60 reads:" "$file" | sed 's/MAPQ = 60 reads: //')

    # Append the extracted values as a new row in the TSV file.
    echo -e "${sample}\t${reference}\t${Total_alignments}\t${Total_aligned}\t${Total_perfect}\t${Total_gapless}\t${Total_properly_paired}\t${MapQ_60_reads}" >> "$output_file"
done