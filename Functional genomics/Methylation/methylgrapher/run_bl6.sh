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



cd /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175958/
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py Align -t 20 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175958/ -fq1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175958_R1.fq.gz -fq2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175958_R2.fq.gz
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MethylCall -t 10 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175958/ -cg_only Y -genotyping_cytosine Y -minimum_mapq 10
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MergeCpG -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175958/


cd /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175959/
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py Align -t 20 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175959/ -fq1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175959_R1.fq.gz -fq2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175959_R2.fq.gz
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MethylCall -t 10 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175959/ -cg_only Y -genotyping_cytosine Y -minimum_mapq 10
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MergeCpG -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175959/


cd /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175960/
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py Align -t 20 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175960/ -fq1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175960_R1.fq.gz -fq2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175960_R2.fq.gz
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MethylCall -t 10 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175960/ -cg_only Y -genotyping_cytosine Y -minimum_mapq 10
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MergeCpG -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175960/


cd /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175961/
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py Align -t 20 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175961/ -fq1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175961_R1.fq.gz -fq2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175961_R2.fq.gz
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MethylCall -t 10 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175961/ -cg_only Y -genotyping_cytosine Y -minimum_mapq 10
python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MergeCpG -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/SRX2175961/


cd /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/merged_bl6/
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py Align -t 20 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/merged_bl6/ -fq1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_bl6_R1.fq.gz -fq2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_bl6_R2.fq.gz
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MethylCall -t 10 -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/merged_bl6/ -cg_only Y -genotyping_cytosine Y -minimum_mapq 10
# python3 /scratch/wzhang/projects/mg020dev/methylGrapher/src/main.py MergeCpG -index_prefix /scratch/wzhang/projects/mouse_pg/wgbs/mg_index1/cc -work_dir /scratch/wzhang/projects/mouse_pg/wgbs/methylgrapher/merged_bl6/ &

