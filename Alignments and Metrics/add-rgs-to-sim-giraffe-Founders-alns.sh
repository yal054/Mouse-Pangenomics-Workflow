#!/usr/bin/env bash
set -euo pipefail

for bam_path in graph/Founders/sim/alignments/md*bam; do
    bam_name=$(basename $bam_path)
    sample=${bam_name##md\.renamed\.sorted\.Founders\.}
    SAMPLE=${sample%%\.surjected\.bam}
    ID="$SAMPLE-lib1"

     samtools addreplacerg -@ 4 \
        -r "ID:${ID}" \
        -r "PU:${ID}" \
        -r "SM:${SAMPLE}" \
        -r "PL:ILLUMINA" \
        -r "LB:${ID}" \
	-o graph/Founders/sim/alignments/sim-add-rgs/"$bam_name" \
	"$bam_path"

done

