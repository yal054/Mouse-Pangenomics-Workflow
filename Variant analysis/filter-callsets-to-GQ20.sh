#!/usr/bin/env bash
set -euo pipefail

LOGDIR="logs/filter-callsets-GQ20"

mkdir -p "$LOGDIR"

shopt -s nullglob

for INPUT_VCF in *callset-vcfs/*/*.vcf.gz; do
    VCF_NAME=$(basename "$INPUT_VCF")
    VCF_DIR=$(dirname "$INPUT_VCF")

    # Skip already-filtered files if the script is re-run.
    if [[ "$VCF_NAME" == GQ20.* ]]; then
        continue
    fi

    OUTPUT_VCF="${VCF_DIR}/GQ20.${VCF_NAME}"

    if [[ -e "$OUTPUT_VCF" ]]; then
        echo "WARNING: Output already exists, skipping: $OUTPUT_VCF" >&2
        continue
    fi

    # Example input:
    # full-callset-vcfs/linear/full.CC001.linear.vcf.gz
    #
    # This creates a compact job name/log stem:
    # full-linear-full.CC001.linear
    REGION=${VCF_DIR%%-callset-vcfs/*}
    METHOD=${VCF_DIR##*/}
    STEM=${VCF_NAME%.vcf.gz}
    JOB_STEM="${REGION}-${METHOD}-${STEM}"

     "bcftools filter \
        -i 'FORMAT/GQ>=20' \
        -Oz \
        -o '${OUTPUT_VCF}' \
        -W=tbi \
        '${INPUT_VCF}'"
done
