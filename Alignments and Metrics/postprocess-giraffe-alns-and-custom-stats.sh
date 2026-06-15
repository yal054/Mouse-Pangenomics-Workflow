"samtools reheader \
   -c \"sed 's/mm10#0#//g'\" \
   $BASE_DIR/$SURJECTED_BAM_NAMEROOT.bam \
  | samtools sort \
    -@ 6 -m 40G -T $TMPDIR \
   -O bam -o $BASE_DIR/renamed.sorted.$SURJECTED_BAM_NAMEROOT.bam \
   - \
  && samtools calmd -b -@ 8 $BASE_DIR/renamed.sorted.$SURJECTED_BAM_NAMEROOT.bam $REF_FASTA > $BASE_DIR/md.renamed.sorted.$SURJECTED_BAM_NAMEROOT.bam \
  && samtools index \
   -@ 8 \
   $BASE_DIR/md.renamed.sorted.$SURJECTED_BAM_NAMEROOT.bam \
  && ln $BASE_DIR/md.renamed.sorted.$SURJECTED_BAM_NAMEROOT.bam.bai $BASE_DIR/md.renamed.sorted.$SURJECTED_BAM_NAMEROOT.bai \
  && bash flagstats-and-custom-stats.sh -b $BASE_DIR/md.renamed.sorted.$SURJECTED_BAM_NAMEROOT.bam -t 8 \
  && samtools stats -@ 8 $BASE_DIR/md.renamed.sorted.$SURJECTED_BAM_NAMEROOT.bam > $BASE_DIR/md.renamed.sorted.$SURJECTED_BAM_NAMEROOT.stats.txt"

