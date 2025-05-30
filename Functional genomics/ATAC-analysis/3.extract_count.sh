#!/bin/bash

# ----------------------------
# 1. Setup and Variables
# ----------------------------

set -e  # Stop on error

SAMPLES=('SAMPLE1' 'SAMPLE2')  # Replace with actual sample names
T=24

script="/path/to/scripts"
OUT="/path/to/output"
pangenome="/path/to/pangenome"

PEAK_BED='union.peaks.bed'

for NAME in "${SAMPLES[@]}"; do

    samtools view -H ${NAME}_CC032.bam > header.sam
    sed 's/SN:CC032#0#chr/SN:chr/g' header.sam > new_header.sam
    samtools reheader new_header.sam ${NAME}_CC032.bam > ${NAME}_CC032.fixed.bam

    sambamba sort -t 64 -o ${NAME}_CC032.fixed.sorted.bam ${NAME}_CC032.fixed.bam

    samtools calmd -bA ${NAME}_CC032.fixed.sorted.bam ../../../0.Allele/0.data/0.genome/genome/CC032_genome.fa >${NAME}_CC032_nm.bam

    samtools view -H ${NAME}_CC072.bam > header.sam
    sed 's/SN:CC072#0#chr/SN:chr/g' header.sam > new_header.sam
    samtools reheader new_header.sam ${NAME}_CC072.bam > ${NAME}_CC072.fixed.bam

    sambamba sort -t 64 -o ${NAME}_CC072.fixed.sorted.bam ${NAME}_CC072.fixed.bam
    samtools calmd -bA ${NAME}_CC072.fixed.sorted.bam ../../../0.Allele/0.data/0.genome/genome/CC072_genome.fa >${NAME}_CC072_nm.bam



    samtools view -h ${NAME}_CC032_nm.bam | awk '$0 ~ /^@/ || $0 ~ /NM:i:0/' | samtools view -b -o ${NAME}_CC032_zero.bam
    samtools view -h ${NAME}_CC072_nm.bam | awk '$0 ~ /^@/ || $0 ~ /NM:i:0/' | samtools view -b -o ${NAME}_CC072_zero.bam

    sambamba view ${NAME}_mm10.bam | awk '{print $1}' | sort >${NAME}_mm10_reads.txt
    sambamba view ${NAME}_CC032_zero.bam | awk '{print $1}' | sort > ${NAME}_CC032_zero_reads.txt
    sambamba view ${NAME}_CC072_zero.bam | awk '{print $1}' | sort > ${NAME}_CC072_zero_reads.txt



    comm -23  ${NAME}_CC032_zero_reads.txt ${NAME}_CC072_zero_reads.txt > ${NAME}_only_CC032.txt
    comm -13 ${NAME}_CC032_zero_reads.txt ${NAME}_CC072_zero_reads.txt > ${NAME}_only_CC072.txt


    cat  ${NAME}_only_CC032.txt|sort -u > ${NAME}_only_CC032_sort.txt
    cat  ${NAME}_only_CC072.txt|sort -u > ${NAME}_only_CC072_sort.txt

    cat ${NAME}_only_CC032.txt ${NAME}_only_CC072.txt | sort -u >  ${NAME}_phased_reads.txt


    comm -23 ${NAME}_mm10_reads.txt ${NAME}_phased_reads.txt |sort -u > ${NAME}_unphased_reads.txt

    samtools view -h ${NAME}_mm10.bam > ${NAME}_mm10.sam
    grep -F -f ${NAME}_only_CC032_sort.txt ${NAME}_mm10.sam > matched.sam
    # 重新添加 header
    samtools view -H ${NAME}_mm10.bam > header.sam
    cat header.sam matched.sam > ${NAME}_only_CC032.sam
    samtools view -Sb ${NAME}_only_CC032.sam > ${NAME}_only_CC032.bam


    samtools view -h ${NAME}_mm10.bam > ${NAME}_mm10.sam
    grep -F -f ${NAME}_only_CC072_sort.txt ${NAME}_mm10.sam > matched.sam
    # 重新添加 header
    samtools view -H ${NAME}_mm10.bam > header.sam
    cat header.sam matched.sam > ${NAME}_only_CC072.sam
    samtools view -Sb ${NAME}_only_CC072.sam > ${NAME}_only_CC072.bam


    shuf ${NAME}_unphased_reads.txt > ${NAME}_shuffled.txt
    split -n l/2 -d ${NAME}_shuffled.txt ${NAME}_unphased_part_
    mv ${NAME}_unphased_part_00 ${NAME}_unphased_A.txt
    mv ${NAME}_unphased_part_01 ${NAME}_unphased_B.txt




    samtools view -h ${NAME}_mm10.bam > ${NAME}_mm10.sam
    grep -F -f ${NAME}_unphased_A.txt ${NAME}_mm10.sam > matched.sam
    # 重新添加 header
    samtools view -H ${NAME}_mm10.bam > header.sam
    cat header.sam matched.sam > ${NAME}_unphased_CC032.sam
    samtools view -Sb ${NAME}_unphased_CC032.sam > ${NAME}_unphased_CC032.bam


    samtools view -h ${NAME}_mm10.bam > ${NAME}_mm10.sam
    grep -F -f ${NAME}_unphased_B.txt ${NAME}_mm10.sam > matched.sam
    # 重新添加 header
    samtools view -H ${NAME}_mm10.bam > header.sam
    cat header.sam matched.sam > ${NAME}_unphased_CC072.sam
    samtools view -Sb ${NAME}_unphased_CC072.sam > ${NAME}_unphased_CC072.bam

    

    bedtools coverage -c -a "$PEAK_BED" -b ${NAME}_only_CC032.bam  >${NAME}_only_CC032.count
    bedtools coverage -c -a "$PEAK_BED" -b ${NAME}_only_CC072.bam  >${NAME}_only_CC072.count
    bedtools coverage -c -a "$PEAK_BED" -b ${NAME}_unphased_CC032.bam  >${NAME}_unphased_CC032.count
    bedtools coverage -c -a "$PEAK_BED" -b ${NAME}_unphased_CC072.bam  >${NAME}_unphased_CC072.count

done