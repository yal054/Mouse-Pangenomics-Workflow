 "mkdir -p $TMPDIR_BASE \
   && bwa-mem2 mem -t 16 $REF_FASTA \
     $FASTQ_R1 \
     $FASTQ_R2 \
   | samtools sort -@ 4 -T $TMPDIR_BASE/sorttmp \
     -O bam -o $BAM_NAMEROOT.bam - \
   && samtools index -@ 20 $BAM_NAMEROOT.bam \
   && ln -f $BAM_NAMEROOT.bam.bai $BAM_NAMEROOT.bai \
   && samtools stats $BAM_NAMEROOT.bam > $BAM_NAMEROOT.stats.txt"

