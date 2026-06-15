#!/bin/bash
#SBATCH --mem=100G
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH -o logs/%x_%A_%a.out
#SBATCH -e logs/%x_%A_%a.err

set -eou pipefail

read BAM VCF_NAME < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

eval $( spack load --sh bcftools@1.21 )

bcftools mpileup \
  --output-type u \
  --gvcf 1 --no-BAQ \
  --ignore-RG \
  -f GRCm38.p6.renamed.filtered.fa \
  "$BAM" \
 | bcftools norm \
  --output-type u \
  --multiallelics - \
  -f GRCm38.p6.renamed.filtered.fa \
  - \
 | bcftools sort -m 80G -T sort-XXXXXX \
  --write-index -o mpileups/"$VCF_NAME".vcf.gz -
