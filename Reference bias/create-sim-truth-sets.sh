#!/bin/bash
#SBATCH --mem=100G
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH -o logs/%x_%A_%a.out
#SBATCH -e logs/%x_%A_%a.err

set -eou pipefail

read CROSS_IN CROSS_OUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

eval $( spack load --sh bcftools@1.21 )

zcat "$CROSS_IN".full.vcf.gz \
 | sed 's/mm10#0#//g' \
 | bcftools view \
   --output-type v \
   --samples ^GRCm39,C57BL_6_T2T_Yu \
   - \
 | grep -Ev 'GT	\.	|GT	[012]	\.|GT	0	0|GT	1	1|GT	2	2|GT	3	3' \
 | bcftools norm \
   --output-type u \
   --multiallelics - \
   -f GRCm38.p6.renamed.filtered.fa \
   - \
 | bcftools sort \
   -m 90G \
   -T tmp-sorting/sort-XXXXXX \
   --write-index \
   -o truth_set_vcfs/"$CROSS_OUT".vcf.gz \
   -
