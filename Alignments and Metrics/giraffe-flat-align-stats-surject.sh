"vg giraffe -p -t 16 \
   -Z $REF.giraffe.gbz \
   -d $REF.dist \
   -m $REF.min \
   -N $SAMPLE \
   -f $FASTQ_R1 \
   -f $FASTQ_R2 \
   -o gam \
   > $ALN_NAMEROOT.gam \
  && vg stats -p 16 -a $ALN_NAMEROOT.gam \
   > $ALN_NAMEROOT.stats.txt \
  && vg surject --threads 16 --bam-output --interleaved \
   --xg-name $REF.giraffe.gbz \
   $ALN_NAMEROOT.gam \
   > $ALN_NAMEROOT.surjected.bam"
