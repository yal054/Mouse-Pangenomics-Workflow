#!/bin/bash

fastp --thread 30 --verbose \
  --dedup --overrepresentation_analysis --detect_adapter_for_pe \
  --in1 indir/129S1_SvImJ_R1.fastq --in2 indir/129S1_SvImJ_R2.fastq \
  --json fastp.129S1_SvImJ.json --html fastp.129S1_SvImJ.html \
  --out1 outdir/129S1_SvImJ_R1.fastq --out2 outdir/129S1_SvImJ_R2.fastq

