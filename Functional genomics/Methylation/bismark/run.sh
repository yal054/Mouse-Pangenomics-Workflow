#!/bin/bash -l
#SBATCH --job-name=bismark
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --time=144:0:00
#SBATCH --mem=200G


eval "$(conda shell.bash hook)"
conda activate py39

module load bismark
module load bowtie2
module load samtools




cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175962/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175962/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175962_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175962_R2.fq.gz /scratch/wzhang/ref/linear/mm10/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175962/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175962//SRX2175962_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175962/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175962_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175962/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm10/bismark//mm10.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175962/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175962/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175962/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175962_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175962_R2.fq.gz /scratch/wzhang/ref/linear/mm39/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175962/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175962//SRX2175962_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175962/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175962_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175962/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm39/bismark//mm39.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175962/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175962/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175962/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175962_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175962_R2.fq.gz /scratch/wzhang/ref/linear/CAST_EiJ/v1/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175962/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175962//SRX2175962_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175962/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175962_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175962/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/CAST_EiJ/v1/bismark//genome.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175962/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175963/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175963/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175963_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175963_R2.fq.gz /scratch/wzhang/ref/linear/mm10/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175963/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175963//SRX2175963_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175963/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175963_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175963/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm10/bismark//mm10.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175963/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175963/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175963/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175963_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175963_R2.fq.gz /scratch/wzhang/ref/linear/mm39/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175963/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175963//SRX2175963_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175963/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175963_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175963/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm39/bismark//mm39.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175963/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175963/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175963/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175963_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175963_R2.fq.gz /scratch/wzhang/ref/linear/CAST_EiJ/v1/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175963/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175963//SRX2175963_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175963/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175963_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175963/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/CAST_EiJ/v1/bismark//genome.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175963/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175964/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175964/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175964_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175964_R2.fq.gz /scratch/wzhang/ref/linear/mm10/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175964/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175964//SRX2175964_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175964/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175964_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175964/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm10/bismark//mm10.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175964/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175964/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175964/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175964_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175964_R2.fq.gz /scratch/wzhang/ref/linear/mm39/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175964/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175964//SRX2175964_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175964/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175964_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175964/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm39/bismark//mm39.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175964/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175964/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175964/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175964_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175964_R2.fq.gz /scratch/wzhang/ref/linear/CAST_EiJ/v1/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175964/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175964//SRX2175964_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175964/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175964_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175964/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/CAST_EiJ/v1/bismark//genome.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175964/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175965/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175965/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175965_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175965_R2.fq.gz /scratch/wzhang/ref/linear/mm10/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175965/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175965//SRX2175965_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175965/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175965_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175965/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm10/bismark//mm10.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/SRX2175965/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175965/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175965/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175965_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175965_R2.fq.gz /scratch/wzhang/ref/linear/mm39/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175965/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175965//SRX2175965_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175965/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175965_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175965/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm39/bismark//mm39.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/SRX2175965/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175965/
# bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175965/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175965_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/SRX2175965_R2.fq.gz /scratch/wzhang/ref/linear/CAST_EiJ/v1/bismark/ > bismark_main.log 2> bismark_main.err
# bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175965/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175965//SRX2175965_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
# bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175965/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_SRX2175965_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

# python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175965/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/CAST_EiJ/v1/bismark//genome.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/SRX2175965/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/merged/
bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/merged/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_R2.fq.gz /scratch/wzhang/ref/linear/mm10/bismark/ > bismark_main.log 2> bismark_main.err
bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/merged/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/merged//merged_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/merged/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_merged_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/merged/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm10/bismark//mm10.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm10/merged/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged/
bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_R2.fq.gz /scratch/wzhang/ref/linear/mm39/bismark/ > bismark_main.log 2> bismark_main.err
bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged//merged_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_merged_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/mm39/bismark//mm39.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/mm39/merged/ &





cd /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/merged/
bismark --parallel 2 -p 5 -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/merged/ -1 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_R1.fq.gz -2 /scratch/wzhang/projects/mouse_pg/wgbs/common/step3.dedup/merged_R2.fq.gz /scratch/wzhang/ref/linear/CAST_EiJ/v1/bismark/ > bismark_main.log 2> bismark_main.err
bismark_methylation_extractor --paired-end --no_overlap --comprehensive --merge_non_CpG --report -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/merged/ --parallel 15 /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/merged//merged_R1_bismark_bt2_pe.bam > bismark_me.log 2> bismark_me.err
bismark2bedGraph --dir /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/merged/ --cutoff 1 --buffer_size=60G -o bismark.cov CpG_context_merged_R1_bismark_bt2_pe.txt > bismark_2bg.log 2> bismark_2bg.err

python3 /scratch/wzhang/scripts/methylation_format_conversion/bismark2tracks.py -cov /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/merged/bismark.cov.gz.bismark.cov.gz -fasta /scratch/wzhang/ref/linear/CAST_EiJ/v1/bismark//genome.fa -o /scratch/wzhang/projects/mouse_pg/wgbs/bismark/cast/merged/




