#!/usr/bin/env bash
set -euo pipefail

VCF_DIR="split_vcfs"
LOGDIR="logs/split-vcfwave"
TMPDIR=""

mkdir -p "$LOGDIR"
mkdir -p "$TMPDIR"

shopt -s nullglob

for vcf in "$VCF_DIR"/vcfwave*.vcf; do
    base=$(basename "$vcf" .vcf)
    contig=${base%.Founders}                                                                                                                                                                                                                                                                                                                                                
    contig=${contig#vcfwave.}

    out="$VCF_DIR/sorted.${base}.vcf.gz"

      "bcftools sort \
        -m 45G --write-index \
	-T $TMPDIR/bcftools-XXXXXX \
	-o $out \
	$vcf"
done
