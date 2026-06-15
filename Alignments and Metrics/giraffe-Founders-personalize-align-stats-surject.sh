"vg giraffe -p -t 16 \
   -Z Founders.gbz \
   --haplotype-name Founders.hapl \
   --kff-name $SAMPLE-kmers.kff \
   --index-basename Founders.diploid-sampled \
   -N $SAMPLE \
   -f $FASTQ_R1 \
   -f $FASTQ_R2 \
   -o gam \
   > $ALN_NAMEROOT.gam \
  && vg stats -p 16 -a $ALN_NAMEROOT.gam \
   > $ALN_NAMEROOT.stats.txt \
  && vg surject --threads 16 --bam-output --interleaved --into-paths mm10_paths.txt \
   --xg-name Founders.gbz \
   $ALN_NAMEROOT.gam \
   > $ALN_NAMEROOT.surjected.bam"
