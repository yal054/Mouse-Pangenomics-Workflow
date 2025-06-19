#!/bin/bash

bwa-mem2 mem -t 16 GRCm38.p6.renamed.filtered.fa PWK_PhJ_30x_R1.fq PWK_PhJ_30x_R2.fq \
 | samtools sort -@ 4 -T $TMP -O bam -o GRCm38v2-ref.PWK_PhJ-query.bam - \
 && samtools index GRCm38v2-ref.PWK_PhJ-query.bam \
 && ln GRCm38v2-ref.PWK_PhJ-query.bam.bai GRCm38v2-ref.PWK_PhJ-query.bai

