#!/bin/bash

# Directory for all intermediate and final output
outdir="chr_prefix_autosomes_X_M"
mkdir -p "$outdir"

# List of files to process
files=(
    "GCA_001624295.1_AKR_J_v1_genomic.fna"
    "GCA_001624475.1_CBA_J_v1_genomic.fna"
    "GCA_001624505.1_DBA_2J_v1_genomic.fna"
    "GCA_001624535.1_FVB_NJ_v1_genomic.fna"
    "GCA_001632525.1_BALB_cJ_v1_genomic.fna"
    "GCA_001632555.1_C57BL_6NJ_v1_genomic.fna"
    "GCA_001632575.1_C3H_HeJ_v1_genomic.fna"
    "GCA_001632615.1_LP_J_v1_genomic.fna"
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

