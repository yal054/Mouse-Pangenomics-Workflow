#!/bin/bash

bcftools mpileup --output-type u --gvcf 1 --no-BAQ -f GRCm38.p6.renamed.filtered.fa renamed.sorted.CC-v1F.CC024xCC023.surjected.bam \
 | bcftools norm --output-type u --multiallelics - -f GRCm38.p6.renamed.filtered.fa - \
 | bcftools sort -m 80G -T $TMP-XXXXXX --write-index -o CC024xCC023.vcf.gz -
