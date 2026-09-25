#!/bin/bash
#SBATCH --mem=12G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J bcftools_stats

read INPUTVCF OUTPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "INPUTVCF: $INPUTVCF"
echo "OUTPUT: $OUTPUT"

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# bcftools
eval $( spack load --sh samtools/wvf7267 )
eval $( spack load --sh bcftools/yz7hzwn )   # bcftools 1.12 (build hash yz7hzwn)

bcftools stats $INPUTVCF > $OUTPUT
echo "Done!"
