#!/usr/bin/env bash

sample1="$1"
sample2="$2"

base_in="30x_downsampled_reads"
base_out="diploid-reads-workflow/reads"

# for R1 and R2
for R in 1 2; do
  out="${base_out}/${sample1}x${sample2}_R${R}.fq"
  : > "$out"    # truncate/create

  for sm in "$sample1" "$sample2"; do
    in="${base_in}/${sm}_30x_R${R}.fq"
    awk -v sm="$sm" 'NR%4==1{sub(/^@/,"@" sm "_")}1' "$in" >> "$out"
  done
done

