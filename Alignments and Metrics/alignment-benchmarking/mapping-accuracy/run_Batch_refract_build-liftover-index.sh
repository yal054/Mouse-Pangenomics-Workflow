#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/refract: refract executable.
#SBATCH --mem=2G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=1
#SBATCH -J refract_build-liftover-index

read PAF INDEX < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval "$(spack load --sh gcc@11.2.0)"

# print parameters to log
echo "PAF:" $PAF
echo "INDEX:" $INDEX

echo "Running refract build-liftover-index..."
time /path/to/refract build-liftover-index $PAF $INDEX
echo "Done!"
