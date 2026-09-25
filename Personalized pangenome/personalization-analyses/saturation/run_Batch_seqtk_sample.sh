#!/bin/bash
#SBATCH --mem=8G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J seqtk_sample

# [Alignment parameters lookup file]
read INPUTFASTQ SEED FRACTION OUTPUTFASTQ < <( sed -n "${SLURM_ARRAY_TASK_ID}p" "$1" )

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# Load the seqtk module
eval $( spack load --sh seqtk )

echo "Input file: $INPUTFASTQ"
echo "Seed: $SEED"
echo "Fraction: $FRACTION"
echo "Output file: $OUTPUTFASTQ"

if [[ "$OUTPUTFASTQ" == *.gz ]]; then
  seqtk sample -s"${SEED}" "$INPUTFASTQ" "$FRACTION" | gzip > "$OUTPUTFASTQ"
else
  seqtk sample -s"${SEED}" "$INPUTFASTQ" "$FRACTION" > "$OUTPUTFASTQ"
fi

echo "Complete!"