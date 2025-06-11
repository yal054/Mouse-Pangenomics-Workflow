#!/bin/bash -l
#SBATCH --job-name=bismark
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --time=167:0:00
#SBATCH --mem=200G

eval "$(conda shell.bash hook)"
conda activate py39

module load bismark
module load bowtie2
module load samtools




cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175958/
bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175958/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175958_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175958_R2.fq.gz /scratch/wzhang/ref/linear/mm39/bismark/ > bismark_main.log 2> bismark_main.err
bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175958/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175958//SRX2175958_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175958/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175958_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175958/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm39/bismark//mm39.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175958/ &



cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175959/
bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175959/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175959_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175959_R2.fq.gz /scratch/wzhang/ref/linear/mm39/bismark/ > bismark_main.log 2> bismark_main.err
bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175959/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175959//SRX2175959_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175959/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175959_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175959/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm39/bismark//mm39.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175959/ &



cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175960/
bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175960/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175960_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175960_R2.fq.gz /scratch/wzhang/ref/linear/mm39/bismark/ > bismark_main.log 2> bismark_main.err
bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175960/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175960//SRX2175960_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175960/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175960_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175960/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm39/bismark//mm39.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175960/ &



cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175961/
bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175961/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175961_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175961_R2.fq.gz /scratch/wzhang/ref/linear/mm39/bismark/ > bismark_main.log 2> bismark_main.err
bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175961/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175961//SRX2175961_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175961/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175961_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175961/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm39/bismark//mm39.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175961/ &



cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged_bl6/
bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged_bl6/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_bl6_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_bl6_R2.fq.gz /scratch/wzhang/ref/linear/mm39/bismark/ > bismark_main.log 2> bismark_main.err
bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged_bl6/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged_bl6//merged_bl6_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged_bl6/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_merged_bl6_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged_bl6/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm39/bismark//mm39.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged_bl6/ &


