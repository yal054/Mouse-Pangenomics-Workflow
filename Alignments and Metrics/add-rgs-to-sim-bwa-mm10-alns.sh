#!/usr/bin/env bash
set -euo pipefail

for bam_path in linear/GRCm38/*bam; do
    bam_name=$(basename $bam_path)
    sample=${bam_name##GRCm38-ref\.}
    SAMPLE=${sample%%-query.bam}
    ID="$SAMPLE-lib1"

     samtools addreplacerg -@ 4 \
        -r "ID:${ID}" \
        -r "PU:${ID}" \
        -r "SM:${SAMPLE}" \
        -r "PL:ILLUMINA" \
        -r "LB:${ID}" \
	-o linear/GRCm38/sim-add-rgs/"$bam_name" \
	"$bam_path"

done

