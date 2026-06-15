#!/usr/bin/env bash
set -euo pipefail

OUTDIR="graph/Founders/alignments/real-fix-chr-lens"

mkdir -p "$OUTDIR"

for bam_path in graph/Founders/alignments/real-add-rgs/*bam; do
    bam_name=$(basename "$bam_path")
    outbam="chr-len-fix.$bam_name"
    sample=${bam_name##md\.renamed\.sorted\.Founders\.}
    SAMPLE=${sample%%\.surjected\.bam}

      "samtools reheader -c './fix-surjected-chr-lens-script.sh' \
        $bam_path > $OUTDIR/$outbam"
done

