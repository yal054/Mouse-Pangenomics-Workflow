#!/bin/bash -l
#SBATCH --job-name=ppr
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=21
#SBATCH --time=144:0:00
#SBATCH --mem=160G





export PROJECT_ROOT=/scratch/wzhang/projects/mouse_pg/ppmg/
export GRAPH_PREFIX=${PROJECT_ROOT}graphs/CC_v2_refs_v1_founders_v2_RI.full/
export KMCKFF=${PROJECT_ROOT}sim_kmer/CC057_CC058_100x/sample.kff


cd /scratch/wzhang/projects/mouse_pg/ppmg/sim_ppr/CC_v2_refs_v1_founders_v2_RI_full_2_CC057_CC058_100x

vg_v1.61.0 haplotypes -v 2 -t 20 --include-reference --preset diploid --diploid-sampling -i ${GRAPH_PREFIX}graph.hapl -k ${KMCKFF} -g ./sampled.gbz ${GRAPH_PREFIX}graph.gbz

vg_v1.61.0 deconstruct --path-prefix mm10 -t 20 --verbose sampled.gbz > deconstruct.mm10.vcf
vg_v1.61.0 deconstruct --path-prefix GRCm39 -t 20 --verbose sampled.gbz > deconstruct.mm39.vcf

vg_v1.61.0 paths --extract-fasta -x sampled.gbz -t 20 --paths-by recombination#1 > r1.fasta
vg_v1.61.0 paths --extract-fasta -x sampled.gbz -t 20 --paths-by recombination#2 > r2.fasta


python3 /scratch/wzhang/scripts/recombinant_fasta_header_fix.py r1.fasta r1f.fasta
python3 /scratch/wzhang/scripts/recombinant_fasta_header_fix.py r2.fasta r2f.fasta



