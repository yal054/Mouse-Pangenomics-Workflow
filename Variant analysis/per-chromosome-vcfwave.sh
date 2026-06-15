#!/usr/bin/env bash
set -euo pipefail

VCF_DIR="split_vcfs"
LOGDIR="logs/split-vcfwave"

mkdir -p "$LOGDIR"

shopt -s nullglob

for vcf in "$VCF_DIR"/*.vcf.gz; do
    base=$(basename "$vcf" .vcf.gz)
    contig=${base%%.*}

    out="$VCF_DIR/vcfwave.${base}.vcf"

"vcfwave -I 1000 \"$vcf\" > \"$out\""

done
