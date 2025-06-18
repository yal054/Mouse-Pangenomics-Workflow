#!/bin/bash

vg giraffe -p -t 16 \
   -Z CC.gbz \
   --haplotype-name CC.hapl \
   --kff-name 129S1_SvImJ-kmers.kff \
   --index-basename CC-v1F.diploid-sampled \
   -N 129S1_SvImJ \
   -f 129S1_SvImJ_30x_R1.fq -f 129S1_SvImJ_30x_R2.fq \
   -o gam \
   > CC-v1F.129S1_SvImJ.gam \
  && vg stats -p 16 -a CC-v1F.129S1_SvImJ.gam > CC-v1F.129S1_SvImJ.stats.txt \
  && vg surject --threads 16 --bam-output --interleaved --into-paths mm10_paths.txt \
   --xg-name CC.gbz CC-v1F.129S1_SvImJ.gam \
   > CC-v1F.129S1_SvImJ.surjected.bam
