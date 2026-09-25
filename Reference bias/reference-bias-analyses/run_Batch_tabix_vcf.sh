#!/bin/bash
#SBATCH --mem=4G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J tabix

read INPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# samtools@1.13
eval $( spack load --sh samtools/5dgya4q )


echo "Input file: "$INPUT

echo "Starting indexing..."
tabix -p vcf $INPUT
echo " Complete!"
