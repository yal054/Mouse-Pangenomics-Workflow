#!/bin/bash 

vg giraffe -p -t 16 \
   -Z F1-v1_Founders-PWK_PhJxCAST_EiJ.gbz \
   -N PWK_PhJ \
   -f PWK_PhJ_30x_R1.fq -f PWK_PhJ_30x_R2.fq \
   -o gam \
   > PWK_PhJxCAST_EiJ.PWK_PhJ.gam \
  && vg stats -p 16 -a PWK_PhJxCAST_EiJ.PWK_PhJ.gam > PWK_PhJxCAST_EiJ.PWK_PhJ.stats.txt \
  && vg surject --threads 16 --bam-output --interleaved --into-paths mm10_paths.txt \
   --xg-name F1-v1_Founders-PWK_PhJxCAST_EiJ.gbz \
   PWK_PhJxCAST_EiJ.PWK_PhJ.gam \
   > PWK_PhJxCAST_EiJ.PWK_PhJ.surjected.bam
