#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/homer/bin/: directory containing HOMER executables.
#SBATCH --mem=32G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J HOMER

# pull in the three fields from your params file
read INPUTPEAKFILE GENOME OUTPUTANNOTATIONS < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

# figure out where the .Annotations should live
OUTDIR=$(dirname "$OUTPUTANNOTATIONS")
mkdir -p "$OUTDIR"
cd "$OUTDIR"

echo "Working in $(pwd)"
echo "Annotating $(basename "$INPUTPEAKFILE") → $(basename "$OUTPUTANNOTATIONS") using $GENOME"

# define annotation stats file for -annStats option. Add .stats to the output file name
stats="$(basename "$OUTPUTANNOTATIONS").stats"

# make sure HOMER is on your PATH
export PATH=$PATH:/path/to/homer/bin/

# run it on the BED basename, spit out the .Annotations basename
annotatePeaks.pl "$(basename "$INPUTPEAKFILE")" "$GENOME" -annStats $stats\
  > "$(basename "$OUTPUTANNOTATIONS")"
