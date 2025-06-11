#!/bin/bash -l
#SBATCH --job-name=mge
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=11
#SBATCH --time=167:0:00
#SBATCH --mem=90G

eval "$(conda shell.bash hook)"
conda activate py312


cd /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175962/
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py Align -t 20 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175962/ -fq1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175962_R1.fq.gz -fq2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175962_R2.fq.gz
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MethylCall -t 10 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175962/ -cg_only Y -genotyping_cytosine Y -minimum_mapq 10
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MergeCpG -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175962/


cd /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175963/
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py Align -t 20 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175963/ -fq1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175963_R1.fq.gz -fq2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175963_R2.fq.gz
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MethylCall -t 10 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175963/ -cg_only Y -genotyping_cytosine Y -minimum_mapq 10
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MergeCpG -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175963/


cd /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175964/
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py Align -t 20 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175964/ -fq1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175964_R1.fq.gz -fq2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175964_R2.fq.gz
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MethylCall -t 10 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175964/ -cg_only Y -genotyping_cytosine Y -minimum_mapq 10
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MergeCpG -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175964/


cd /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175965/
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py Align -t 20 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175965/ -fq1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175965_R1.fq.gz -fq2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175965_R2.fq.gz
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MethylCall -t 10 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175965/ -cg_only Y -genotyping_cytosine Y -minimum_mapq 10
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MergeCpG -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175965/ 


cd /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/merged/
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py Align -t 20 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/merged/ -fq1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_R1.fq.gz -fq2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_R2.fq.gz
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MethylCall -t 10 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/merged/ -cg_only Y -genotyping_cytosine Y -minimum_mapq 10
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MergeCpG -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/merged/ &

