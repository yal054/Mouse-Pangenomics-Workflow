#!/usr/bin/env bash
set -euo pipefail

OUTDIR="graph/Founders/alignments/real-sort-by-chr"
TMPDIR=""

mkdir -p "$OUTDIR"

for bam_path in graph/Founders/alignments/real-fix-chr-lens/*bam; do
    bam_name=$(basename "$bam_path")
    outbam="$OUTDIR/chr-sorted.$bam_name"
    sample=${bam_name##chr-len-fix\.md\.renamed\.sorted\.Founders\.}
    SAMPLE=${sample%%\.surjected\.bam}

    SM_TMPDIR="$TMPDIR/$SAMPLE"
    mkdir -p "$SM_TMPDIR"

      "java -Xmx38g -jar /usr/picard/picard.jar ReorderSam \
        -I $bam_path \
	-O $outbam \
	-SD GRCm38.p6.renamed.filtered.dict \
	--TMP_DIR $SM_TMPDIR \
	--CREATE_INDEX true"
done

