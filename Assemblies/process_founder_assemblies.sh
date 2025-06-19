#!/bin/bash

# Directory for all intermediate and final output
outdir="founders_chr_prefix_autosomes_X_M"
mkdir -p "$outdir"

# List of files to process
files=(
    "GCA_001624215.1_A_J_v1_genomic.fna"
    "GCA_001624185.1_129S1_SvImJ_v1_genomic.fna"
    "GCA_001624675.1_NOD_ShiLtJ_v1_genomic.fna"
    "GCA_001624745.1_NZO_HlLtJ_v1_genomic.fna"
    "GCA_001624835.1_WSB_EiJ_v1_genomic.fna"
    "GCA_001624445.1_CAST_EiJ_v1_genomic.fna"
    "GCA_001624775.1_PWK_PhJ_v1_genomic.fna"
)

for file in "${files[@]}"; do
    # Strip off the .fna extension to get a base name
    NAMEROOT="${file%.fna}"
    
    # 1) Rename chromosomes with a "chr" prefix and mitochondrion as "chrM"
    #    This sed approach completely replaces the header with just ">chrN", ">chrX", or ">chrM"
    #    and ignores scaffolds or other contigs. Any lines not matching these patterns
    #    will remain unchanged (and then be skipped in the final extraction).
    sed -E \
        -e 's/^>.* chromosome ([0-9]{1,2}),.*/>chr\1/' \
        -e 's/^>.* chromosome X,.*/>chrX/' \
        -e 's/^>.*mitochondrion.*/>chrM/' \
        "$file" > "${outdir}/${NAMEROOT}.renamed.fna"

    # 2) Index the renamed FASTA
    samtools faidx "${outdir}/${NAMEROOT}.renamed.fna"

    # 3) Extract the desired chromosomes (1..19, X, M) and write the final file
    #    Any lines not matching those references (e.g., scaffolds) will be excluded.
    samtools faidx \
        -o "${outdir}/${NAMEROOT}.renamed.filtered.fna" \
        "${outdir}/${NAMEROOT}.renamed.fna" \
        chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 \
        chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chrX chrM

    # 4) Clean up intermediate files
    rm "${outdir}/${NAMEROOT}.renamed.fna" \
       "${outdir}/${NAMEROOT}.renamed.fna.fai"
done

