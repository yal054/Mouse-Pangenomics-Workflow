#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/FastQC/fastqc: FastQC executable.
#SBATCH --mem=32G
#SBATCH --cpus-per-task=8
#SBATCH -N 1
#SBATCH -J fastqc

# [Alignment parameters lookup file]
read INPUT OUTPUTDIRECTORY < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )
## COUNT TAKES ON VALUE OF TRUE OR FALSE

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
#echo "Loading software..."
#eval $( spack load --sh fastqc@0.11.9 )

echo "Input file: "$INPUT
echo "Output directory: "$OUTPUTDIRECTORY

mkdir -p $OUTPUTDIRECTORY

echo "Starting QC..."
/path/to/FastQC/fastqc -t 8 $INPUT -o $OUTPUTDIRECTORY
echo " ...Complete!"
