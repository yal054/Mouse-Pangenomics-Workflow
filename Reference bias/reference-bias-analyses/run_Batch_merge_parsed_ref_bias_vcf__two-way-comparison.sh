#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/merge_parsed_ref_bias_vcf.py: script included in this repository at `Reference bias/reference-bias-analyses/merge_parsed_ref_bias_vcf.py`.
#SBATCH --mem=4G
#SBATCH -n 1
#SBATCH -N 1

read INPUT1 INPUT2 OUTPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# python 3.8.12
eval $( spack load --sh /pudl6n3 )

echo "INPUT: $INPUT1"
echo "INPUT: $INPUT2"
echo "OUTPUT: $OUTPUT"

echo "Running script..."
python3 /path/to/merge_parsed_ref_bias_vcf.py $INPUT1 $INPUT2 -o $OUTPUT

echo "Done!"