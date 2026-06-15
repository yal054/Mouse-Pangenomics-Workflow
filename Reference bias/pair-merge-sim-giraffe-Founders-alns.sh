#!/usr/bin/env bash
set -euo pipefail

while IFS=$'\t' read -r SAMPLE1 SAMPLE2; do

    BAM1="graph/Founders/sim/alignments/sim-add-rgs/md.renamed.sorted.Founders.$SAMPLE1.surjected.bam"
    BAM2="graph/Founders/sim/alignments/sim-add-rgs/md.renamed.sorted.Founders.$SAMPLE2.surjected.bam"
    MERGED_BAM="graph/Founders/sim/alignments/sim-merged/$SAMPLE1-$SAMPLE2.bam"
    BAM_INDEX="graph/Founders/sim/alignments/sim-merged/$SAMPLE1-$SAMPLE2.bam.bai"
    BAM_INDEX_LINK="graph/Founders/sim/alignments/sim-merged/$SAMPLE1-$SAMPLE2.bai"

     "samtools merge -@ 8 \
        -o $MERGED_BAM \
	$BAM1 \
	$BAM2 \
      && samtools index -@ 8 $MERGED_BAM \
      && ln -f $BAM_INDEX $BAM_INDEX_LINK"

done < pairs.txt
