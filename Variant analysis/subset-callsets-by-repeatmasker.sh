#!/usr/bin/env bash
set -euo pipefail

DV_ROOT=""
HAP_DIR="parsed-hapfiles"
REGION_DIR="hap-target-regions"

HARD_BED="mm10.repeat_trf_segdup.challenge_union.bed"

FULL_OUT_ROOT="full-callset-vcfs"
EASY_OUT_ROOT="easy-callset-vcfs"
HARD_OUT_ROOT="hard-callset-vcfs"

LOGDIR="logs/subset-callsets"

mkdir -p "$REGION_DIR" "$LOGDIR"

for method in linear surjected; do
    mkdir -p \
      "$FULL_OUT_ROOT/$method" \
      "$EASY_OUT_ROOT/$method" \
      "$HARD_OUT_ROOT/$method"
done

shopt -s nullglob

for HAP_FILE in "$HAP_DIR"/CC*.tsv; do
    SAMPLE=$(basename "$HAP_FILE" .tsv)

    TARGET_REGIONS="$REGION_DIR/${SAMPLE}.hap_regions.tsv"

    for METHOD in linear surjected; do
        case "$METHOD" in
            linear)
                METHOD_SUFFIX="bwa"
                ;;
            surjected)
                METHOD_SUFFIX="Founders-surjected-chr-sort"
                ;;
            *)
                echo "ERROR: Unknown method: $METHOD" >&2
                exit 1
                ;;
        esac

        INPUT_VCF="${DV_ROOT}/${SAMPLE}-${METHOD_SUFFIX}/${SAMPLE}.vcf.gz"

        if [[ ! -s "$INPUT_VCF" ]]; then
            echo "WARNING: Missing input VCF, skipping: $INPUT_VCF" >&2
            continue
        fi

        FULL_OUT="${FULL_OUT_ROOT}/${METHOD}/full.${SAMPLE}.${METHOD}.vcf.gz"
        EASY_OUT="${EASY_OUT_ROOT}/${METHOD}/easy.${SAMPLE}.${METHOD}.vcf.gz"
        HARD_OUT="${HARD_OUT_ROOT}/${METHOD}/hard.${SAMPLE}.${METHOD}.vcf.gz"

         "bcftools view \
            -T '${HARD_BED}' \
            -Oz \
            -o '${HARD_OUT}' \
            -W=tbi \
            '${FULL_OUT}'"

         "bcftools view \
            -T '^${HARD_BED}' \
            -Oz \
            -o '${EASY_OUT}' \
            -W=tbi \
            '${FULL_OUT}'"

    done
done
