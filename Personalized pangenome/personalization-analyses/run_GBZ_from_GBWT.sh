#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/vg: vg executable; use the version described in the manuscript.
#SBATCH --mem=64G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=8
#SBATCH -J build_gbz

read INPUT_GRAPH GBWT OUTPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Using graph: $INPUT_GRAPH"
echo "Using GBWT: $GBWT"
echo "Output GBZ: $OUTPUT"

echo "Starting chunk merge..."

/path/to/vg gbwt --num-threads 16 \
  -x "$INPUT_GRAPH" "$GBWT" \
  --gbz-format -g "$OUTPUT"
exit

echo " Complete!"
