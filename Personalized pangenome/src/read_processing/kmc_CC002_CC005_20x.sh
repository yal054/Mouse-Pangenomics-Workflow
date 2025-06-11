#!/bin/bash -l
#SBATCH --job-name=kmc
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=40
#SBATCH --time=144:0:00
#SBATCH --mem=150G




cd /scratch/wzhang/projects/mouse_pg/ppmg/sim_kmer/CC002_CC005_20x/

# -k<len> - k-mer length (k from 1 to 256; default: 25)
# -m<size> - max amount of RAM in GB (from 1 to 1024); default: 12
# -o<kmc/kff> - output in KMC of KFF format; default: KMC
kmc -k29 -m128 -okff -t40 -hp @fq.list ./sample ./

