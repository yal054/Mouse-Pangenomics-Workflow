#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/convert_GFA_to_rGFA.py: GFA-to-rGFA conversion script included beside this wrapper.
#SBATCH --mem=12G
#SBATCH -n 1
#SBATCH -N 1

read INPUTGFA REFERENCE OUTPUTRGFA < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# Load the required module
eval $( spack load --sh /pudl6n3 )

echo "Job to convert GFA to rGFA for $INPUTGFA"
echo "With reference: $REFERENCE"

# Convert GFA to rGFA
python3 /path/to/convert_GFA_to_rGFA.py \
$INPUTGFA \
-r $REFERENCE \
-o $OUTPUTRGFA
