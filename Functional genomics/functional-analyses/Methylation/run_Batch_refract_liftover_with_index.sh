#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/refract: refract executable.
#SBATCH --mem=2G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=1
#SBATCH -J refract_build-liftover-index

read INDEX INPUT OUTPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval "$(spack load --sh gcc@11.2.0)"

# print parameters to log
echo "INDEX:" $INDEX
echo "INPUT:" $INPUT
echo "OUTPUT:" $OUTPUT

echo "Running refract liftover..."
time /path/to/refract liftover --index $INDEX -q 5 -l 50000 -d 1 $INPUT > $OUTPUT
echo "Done!"
