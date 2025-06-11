#!/bin/bash -l
#SBATCH --job-name=mc_quad
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=31
#SBATCH --time=144:0:00
#SBATCH --mem=104G



module load singularity


cd /scratch/wzhang/projects/mouse_pg/ppmg/sim_ppr/LT-v1F-CC004-CC017_full_2_CC004_CC017_30x

singularity exec --bind /scratch/wzhang/:/scratch/wzhang/ /scratch/wzhang/projects/mouse_pg/graph_building/cactus_v2.9.3.sif bash /scratch/wzhang/scripts/build_mc_graph.sh quad mm10 /scratch/wzhang/projects/mouse_pg/ppmg/sim_ppr/LT-v1F-CC004-CC017_full_2_CC004_CC017_30x/graph/ /scratch/wzhang/projects/mouse_pg/ppmg/sim_ppr/LT-v1F-CC004-CC017_full_2_CC004_CC017_30x/seqfile.tsv 31 400G



