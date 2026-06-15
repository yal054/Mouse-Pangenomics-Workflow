#!/bin/bash
#SBATCH --mem=100G
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH -o logs/%x_%A_%a.out
#SBATCH -e logs/%x_%A_%a.err

set -eou pipefail

read SAMPLE < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

# switch to Juan's spack
source /ref/twlab/software/JFMV/spack/share/spack/setup-env.sh

eval $( spack load --sh bcftools@1.21 )

bcftools isec \
  --threads 6 -n=2 -w1 -c all \
  -o isec_output/"$SAMPLE".intersected.vcf.gz \
  mpileups/"$SAMPLE".vcf.gz \
  truth_set_vcfs/"$SAMPLE".vcf.gz
