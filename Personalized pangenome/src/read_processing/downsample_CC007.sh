#!/bin/bash -l
#SBATCH --job-name=downsample
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=6
#SBATCH --time=144:0:00
#SBATCH --mem=1G
#SBATCH --output=/scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/bash/%j.out




python3 /scratch/wzhang/scripts/fastq_downsample_ratio.py /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R2.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/5x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/5x/CC007_R2.fq.gz 0.05 &
python3 /scratch/wzhang/scripts/fastq_downsample_ratio.py /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R2.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/10x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/10x/CC007_R2.fq.gz 0.1 &
python3 /scratch/wzhang/scripts/fastq_downsample_ratio.py /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R2.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/15x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/15x/CC007_R2.fq.gz 0.15 &
python3 /scratch/wzhang/scripts/fastq_downsample_ratio.py /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R2.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/20x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/20x/CC007_R2.fq.gz 0.2 &
python3 /scratch/wzhang/scripts/fastq_downsample_ratio.py /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R2.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/30x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/30x/CC007_R2.fq.gz 0.3 &
python3 /scratch/wzhang/scripts/fastq_downsample_ratio.py /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/100x/CC007_R2.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/50x/CC007_R1.fq.gz /scratch/wzhang/projects/mouse_pg/ppmg/sim_fastq/50x/CC007_R2.fq.gz 0.5


sleep 600
