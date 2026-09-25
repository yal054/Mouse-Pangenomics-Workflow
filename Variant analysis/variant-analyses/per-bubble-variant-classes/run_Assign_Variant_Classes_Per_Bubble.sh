#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/Assign_Variant_Classes_Per_Bubble.py: script included in this repository at `Variant analysis/variant-analyses/per-bubble-variant-classes/Assign_Variant_Classes_Per_Bubble.py`.
#SBATCH --mem=32G
#SBATCH -n 1
#SBATCH -N 1

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# python 3.8.12
eval $( spack load --sh /pudl6n3 )

VCF=$1
OUT=$2

echo "Assigning variant classes"
echo "VCF: $VCF"
echo "OUT: $OUT"

echo "Running assignment"
python /path/to/Assign_Variant_Classes_Per_Bubble.py $VCF -o $OUT
echo "Done"
