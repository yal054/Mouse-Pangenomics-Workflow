#!/bin/bash

bcftools isec --threads 6 -n=2 -w1 -c all \
    -o true-dip.CC.129S1_SvImJxCAST_EiJ.intersected.vcf.gz \
    129S1_SvImJxCAST_EiJ.vcf.gz \
    truth-set.F1-v1_Founders-129S1_SvImJxCAST_EiJ.vcf.gz

