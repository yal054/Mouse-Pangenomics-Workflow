#!/bin/bash

samtools reheader -c \"sed 's/mm10#0#//g'\" 129S1_SvImJxCAST_EiJ.CAST_EiJ.surjected.bam \
  | samtools sort -@ 6 -m 40G -T $TMP -O bam -o renamed.sorted.129S1_SvImJxCAST_EiJ.CAST_EiJ.surjected.bam - \
  && samtools index  --threads 8 renamed.sorted.129S1_SvImJxCAST_EiJ.CAST_EiJ.surjected.bam \
  && ln renamed.sorted.129S1_SvImJxCAST_EiJ.CAST_EiJ.surjected.bam.bai renamed.sorted.129S1_SvImJxCAST_EiJ.CAST_EiJ.surjected.bai
