#!/bin/bash

while IFS=$'\t' read -r sample1 sample2; do
  add_sample_prefix_and_combine_pair.sh ${sample1} ${sample2}
done < crosses.tsv

