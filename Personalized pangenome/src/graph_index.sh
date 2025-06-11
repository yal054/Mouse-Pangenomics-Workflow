#!/bin/bash -l
#SBATCH --job-name=gi
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=30
#SBATCH --time=144:0:00
#SBATCH --mem=180G




eval "$(conda shell.bash hook)"
conda activate py312


# GFA2GBZ conversion
vg_v1.61.0 gbwt --gbz-format -g graph.gbz -G graph.gfa


# Creating index for personalized pangenome
# --no-nested-distance (v1.63.1) OR --snarl-limit 1 (v1.61.0)
vg_v1.61.0 index --snarl-limit 1 -j graph.dist graph.gbz
vg_v1.61.0 gbwt -p --num-threads 30 -r graph.ri -Z graph.gbz
vg_v1.61.0 haplotypes -v 2 -t 30 -H graph.hapl graph.gbz















