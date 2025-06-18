#!/bin/bash

samtools merge -@ 6 -o diploid.F1-ref.PWK_PhJxCAST_EiJ-query.bam renamed.sorted.PWK_PhJxCAST_EiJ.PWK_PhJ.surjected.bam renamed.sorted.PWK_PhJxCAST_EiJ.CAST_EiJ.surjected.bam \
  && samtools index -@ 6 diploid.F1-ref.PWK_PhJxCAST_EiJ-query.bam \
  && ln diploid.F1-ref.PWK_PhJxCAST_EiJ-query.bam.bai diploid.F1-ref.PWK_PhJxCAST_EiJ-query.bai
