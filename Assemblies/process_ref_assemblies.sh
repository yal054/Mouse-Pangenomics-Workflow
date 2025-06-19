#!/bin/bash

# Directory for all intermediate and final output
outdir="refs_chr_prefix_autosomes_X_Y_M"
mkdir -p "$outdir"

# List of files to process
files=(
    "GRCm38.p6.fa"
    "GRCm39.fa"
)

for file in "${files[@]}"; do
    # Strip off the .fa extension to get a base name
    BASENAME="${file%.fa}"

    # 1) Rename chromosomes strictly if they are "chromosome N," or "chromosome X,".
    #    Lines like "chromosome 1 unlocalized" or "chromosome 1 patch" won't match
    #    because we require a comma immediately after the digit(s) or 'X'.
    #    Also rename any line mentioning 'mitochondrion' to '>chrM'.
    sed -E \
        -e 's/^>.* chromosome ([0-9]{1,2}),.*/>chr\1/' \
        -e 's/^>.* chromosome X,.*/>chrX/' \
        -e 's/^>.* chromosome Y,.*/>chrY/' \
        -e 's/^>.*mitochondrion.*/>chrM/' \
        "$file" > "${outdir}/${BASENAME}.renamed.fa"

    # 2) Index the renamed FASTA
    samtools faidx "${outdir}/${BASENAME}.renamed.fa"

    # 3) Extract only chr1..chr19, chrX, chrY, and chrM into a final file
    samtools faidx \
        -o "${outdir}/${BASENAME}.renamed.filtered.fa" \
        "${outdir}/${BASENAME}.renamed.fa" \
        chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 \
        chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chrX chrY chrM

    # 4) Clean up intermediate files, leaving only the final filtered FASTA
    rm "${outdir}/${BASENAME}.renamed.fa" \
       "${outdir}/${BASENAME}.renamed.fa.fai"
done

