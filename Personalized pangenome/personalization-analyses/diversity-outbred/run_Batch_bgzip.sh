#!/bin/bash
#SBATCH --mem=2G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=12
#SBATCH -J bgzip_compression

# [Alignment parameters lookup file]
read INPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )
## COUNT TAKES ON VALUE OF TRUE OR FALSE

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)

echo "Input file: "$INPUT

echo "Starting compression..."
bgzip -@ 12 $INPUT
echo " Complete!"
