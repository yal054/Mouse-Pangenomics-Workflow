#!/bin/bash
#SBATCH --mem=2G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=8
#SBATCH -J samtools_subsample

read INPUT OUTPUT FRACTION < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

SEED=42

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools@1.13/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)

# print parameters to log
echo "INPUT: $INPUT"
echo "OUTPUT: $OUTPUT"
echo "FRACTION: $FRACTION"
echo "SEED: $SEED"

echo "Samtools subsampling..."
samtools view -@ 8 -b --subsample $FRACTION --subsample-seed $SEED $INPUT > $OUTPUT
echo "Done!"
