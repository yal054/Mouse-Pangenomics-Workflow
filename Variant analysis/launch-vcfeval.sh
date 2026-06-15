#!/usr/bin/env bash
set -euo pipefail

SDF="../mm10-SDF"

RESULT_ROOT="GQ20-filtered-vcfeval-results"
LOGDIR="logs/GQ20-filtered-vcfeval"

mkdir -p "$RESULT_ROOT" "$LOGDIR"

for REGION in full easy hard; do
    TRUTH_DIR="${REGION}-truthset-vcfs"

    for METHOD in linear surjected; do
        CALLSET_DIR="${REGION}-callset-vcfs/${METHOD}"
        OUT_PARENT="${RESULT_ROOT}/${REGION}/${METHOD}"

        mkdir -p "$OUT_PARENT"

        for TRUTH_VCF in "$TRUTH_DIR"/"${REGION}".*.truthset.vcf.gz; do
            TRUTH_NAME=$(basename "$TRUTH_VCF")

            SAMPLE=${TRUTH_NAME#${REGION}.}
            SAMPLE=${SAMPLE%.truthset.vcf.gz}

            CALLSET_VCF="${CALLSET_DIR}/GQ20.${REGION}.${SAMPLE}.${METHOD}.vcf.gz"
            EVAL_OUT="${OUT_PARENT}/${REGION}.${SAMPLE}.${METHOD}.vcfeval"

            if [[ ! -s "$CALLSET_VCF" ]]; then
                echo "WARNING: Missing callset VCF, skipping: $CALLSET_VCF" >&2
                continue
            fi

            if [[ -e "$EVAL_OUT" ]]; then
                echo "WARNING: Output already exists, skipping: $EVAL_OUT" >&2
                continue
            fi

             "rtg vcfeval \
                -T ${THREADS} \
                -b '${TRUTH_VCF}' \
                -c '${CALLSET_VCF}' \
                -o '${EVAL_OUT}' \
                -t '${SDF}/'"
        done
    done
done
