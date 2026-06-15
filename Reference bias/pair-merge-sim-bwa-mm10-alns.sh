#!/usr/bin/env bash
set -euo pipefail

while IFS=$'\t' read -r SAMPLE1 SAMPLE2; do

    BAM1="linear/GRCm38/sim-add-rgs/GRCm38-ref.$SAMPLE1-query.bam"
    BAM2="linear/GRCm38/sim-add-rgs/GRCm38-ref.$SAMPLE2-query.bam"
    MERGED_BAM="linear/GRCm38/sim-merged/$SAMPLE1-$SAMPLE2.bam"

     samtools merge -@ 8 \
        -o "$MERGED_BAM" \
	"$BAM1" \
	"$BAM2"

done < pairs.txt
