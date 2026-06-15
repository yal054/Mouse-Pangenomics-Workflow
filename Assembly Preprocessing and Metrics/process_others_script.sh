#!/bin/bash

# Directory for all intermediate and final output
outdir="others_chr_prefix_autosomes_X_Y_M"
mkdir -p "$outdir"

# List of files to process
files=(
    "GCA_921997125.2_C3H_HeJ_v3_genomic.fna"
    "GCA_921997145.2_BALB_cJ_v3_genomic.fna"
    "GCA_921998315.2_DBA_2J_v3_genomic.fna"
    "GCA_921998635.2_FVB_NJ_v3_genomic.fna"
    "GCA_921998905.2_CBA_J_v3_genomic.fna"
    "GCA_921999095.2_JF1_MsJ_v3_genomic.fna"
    "GCA_921999865.2_C57BL_6NJ_v3_genomic.fna"
    "GCA_922000895.2_AKR_J_v3_genomic.fna"
    "GCA_947599735.1_LP_J_v3_genomic.fna"
)

for file in "${files[@]}"; do
    # Strip off the .fna extension to get a base name
    BASENAME="${file%.fna}"

    # 1) Rename chromosomes and mitochondrion
    sed -E '/^>/{
        s/.*chromosome: ([0-9]+|X|Y).*/>chr\1/;
        s/.*organelle: mitochondrion.*/>chrM/;
    }' "$file" > "${outdir}/${BASENAME}.renamed.fa"

    # 2) Index the renamed FASTA
    samtools faidx "${outdir}/${BASENAME}.renamed.fa"

    # 3) Build a list of valid chromosome names from the fai file
    # This regex matches exactly: chr1-chr9, chr10-chr19, chrX, chrY, or chrM.
    valid_chrs=$(grep -E '^chr([1-9]|1[0-9]|X|Y|M)' "${outdir}/${BASENAME}.renamed.fa.fai" | cut -f1 | tr '\n' ' ')

    # 4) Extract only the sequences that actually exist
    samtools faidx \
        -o "${outdir}/${BASENAME}.renamed.filtered.fa" \
        "${outdir}/${BASENAME}.renamed.fa" $valid_chrs

done

