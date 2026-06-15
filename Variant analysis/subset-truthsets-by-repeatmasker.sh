#!/usr/bin/env bash
set -euo pipefail

HARD_BED="mm10.repeat_trf_segdup.challenge_union.bed"

FULL_DIR="full-truthset-vcfs"
EASY_DIR="easy-truthset-vcfs"
HARD_DIR="hard-truthset-vcfs"

LOGDIR="logs/subset-truthsets"

mkdir -p "$EASY_DIR" "$HARD_DIR" "$LOGDIR"

shopt -s nullglob

for FULL_VCF in "$FULL_DIR"/full.*.truthset.vcf.gz; do
    VCF_NAME=$(basename "$FULL_VCF")

    SAMPLE=${VCF_NAME#full.}
    SAMPLE=${SAMPLE%.truthset.vcf.gz}

    EASY_OUT="$EASY_DIR/easy.${SAMPLE}.truthset.vcf.gz"
    HARD_OUT="$HARD_DIR/hard.${SAMPLE}.truthset.vcf.gz"

     "bcftools view \
        -T '${HARD_BED}' \
        -Oz \
        -o '${HARD_OUT}' \
        -W=tbi \
        '${FULL_VCF}'"

     "bcftools view \
        -T '^${HARD_BED}' \
        -Oz \
        -o '${EASY_OUT}' \
        -W=tbi \
        '${FULL_VCF}'"

done
