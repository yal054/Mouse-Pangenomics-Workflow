#!/usr/bin/env bash
set -euo pipefail

for VCF_PATH in truthset-vcfs/*; do

    VCF_NAME=$(basename "$VCF_PATH")
    SAMPLE=${VCF_NAME%%\.truthset\.vcf\.gz}

    LSF_DOCKER_PRESERVE_ENVIRONMENT=false \
    LSF_DOCKER_VOLUMES="/home/johnegarza:/home/johnegarza /storage3/fs1/hprc_analysis/Active:/storage3/fs1/hprc_analysis/Active /storage2/fs1/hprc/Active:/storage2/fs1/hprc/Active /scratch1/fs1/hprc/johnegarza:/scratch1/fs1/hprc/johnegarza" \
    bsub \
      -J "index-${SAMPLE}" \
      -o "logs/index-${SAMPLE}-truthset-%J.out" \
      -e "logs/index-${SAMPLE}-truthset-%J.err" \
      -G compute-hprc \
      -n 1 \
      -M "20G" \
      -R "select[mem>20G] rusage[mem=20G]" \
      -q general \
      -a 'docker(staphb/bcftools:1.21)' \
      "bcftools index -t $VCF_PATH"

done
