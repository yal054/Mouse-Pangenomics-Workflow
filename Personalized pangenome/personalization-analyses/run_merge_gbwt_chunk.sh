#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/vg: vg executable; use the version described in the manuscript.
#SBATCH --mem=64G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=8
#SBATCH -J merge_gbwt_chunk

read CHUNK_LIST < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

OUT="chunk_$(basename ${CHUNK_LIST}).gbwt"

echo "Chunk list: $CHUNK_LIST"
echo "Output: $OUT"

echo "Starting chunk merge..."
/path/to/vg gbwt --num-threads 8 -m $(tr '\n' ' ' < "$CHUNK_LIST") -o "$OUT"
echo " Complete!"

echo "Done."