#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/analyze_variant_capture.py: script included in this repository at `Variant analysis/variant-analyses/ri-population-genetics/analyze_variant_capture.py`.
#SBATCH --mem=72G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J analyze_variant_capture
#SBATCH --cpus-per-task=8

read INPUT OUTPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# python 3.8.12
eval $( spack load --sh /pudl6n3 )
# py-pandas@1.3.4
eval $( spack load --sh /ohxhs7n )
eval $( spack load --sh py-numpy/i7mcgz4 )   # py-numpy, version not recorded (build hash i7mcgz4)

echo "INPUT: $INPUT"
echo "OUTPUT: $OUTPUT"

echo "Running script..."
python3.8 /path/to/analyze_variant_capture.py --threads 8 --output_file $OUTPUT $INPUT

echo "Done!"