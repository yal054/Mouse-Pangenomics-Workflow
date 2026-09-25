#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/Ixchel/SourceCode/Ixchel.py: Ixchel entry-point script.
#SBATCH --mem=8G
#SBATCH -n 1
#SBATCH -N 1

read GRAPHMETHYLFILE PRECOMPUTEDDB METHYLCOUTPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# Load the necessary modules
## python@3.7.3
eval $( spack load --sh /si3fu6h )
eval $( spack load --sh py-numpy/i7mcgz4 )   # py-numpy, version not recorded (build hash i7mcgz4)
eval $( spack load --sh py-jsonpickle@1.4.1 )
## py-dill@0.3.4
eval $( spack load --sh py-dill/syrzqvm )
## py-tqdm
eval $( spack load --sh py-tqdm/vi7e33q )


echo "Software loaded"

echo "Input files:"
echo "GraphMethyl file: $GRAPHMETHYLFILE"
echo "Precomputed database: $PRECOMPUTEDDB"
echo "Output methylC file: $METHYLCOUTPUT"

echo "Converting GraphMethyl to MethylC..."
python3 /path/to/Ixchel/SourceCode/Ixchel.py convertGraphMethylToMethylC $GRAPHMETHYLFILE $PRECOMPUTEDDB $METHYLCOUTPUT
echo "Conversion done"

