#!/usr/bin/env bash
set -euo pipefail

VCF="Founders.mm10.vcf.gz"
CONTIG_FILE="vcf-stats.txt"   # first column = contig name

OUTDIR="split_vcfs"
LOGDIR="logs"

mkdir -p "$OUTDIR" "$LOGDIR"

"awk 'NF && \$1 !~ /^#/ {print \$1}' \"$CONTIG_FILE\" | sort -u |
while read -r C; do
    echo \"Splitting \$C\"

    bcftools view \
      -r \"\$C\" \
      -Oz \"$VCF\" \
      -o \"$OUTDIR/\$C.Founders.vcf.gz\"

    bcftools index -t \"$OUTDIR/\$C.Founders.vcf.gz\"
done
"
