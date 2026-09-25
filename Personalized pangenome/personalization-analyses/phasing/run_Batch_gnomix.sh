#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/gnomix_env/bin/activate: activation script for your Gnomix Python environment.
# /path/to/gnomix/gnomix.py: Gnomix entry-point script.
#SBATCH --mem=8G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=1

read SAMPLE_VCF OUTPUT_DIR CHROM PHASE MODEL < <( sed -n ${SLURM_ARRAY_TASK_ID}p "$1" )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# @3.8.12
eval $( spack load --sh python/pudl6n3 )


source /path/to/gnomix_env/bin/activate

echo "Running gnomix..."
echo "Sample VCF: $SAMPLE_VCF"
echo "Output Dir: $OUTPUT_DIR"
echo "Chromosome: $CHROM"
echo "Phase: $PHASE"
echo "Model: $MODEL"

python /path/to/gnomix/gnomix.py \
$SAMPLE_VCF \
$OUTPUT_DIR \
$CHROM \
$PHASE \
$MODEL

echo "Finished!"