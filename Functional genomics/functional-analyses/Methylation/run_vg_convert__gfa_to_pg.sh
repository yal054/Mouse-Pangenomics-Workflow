#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/vg: vg executable; use the version described in the manuscript.
#SBATCH --mem=128G
#SBATCH -n 20
#SBATCH -N 1

GFA=$1
PG=$2

echo "Converting GFA to PG"
echo "GFA: $GFA"
echo "PG: $PG"

echo "Running vg convert"
/path/to/vg convert -t 20 -p -g $GFA >$PG
