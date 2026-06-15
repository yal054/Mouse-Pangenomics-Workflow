for BAM in alignments/linear/$REF/merge-dir/sample-merge/*bam; do

    SAMPLE=$(basename ${BAM%%.merged.bam} )
    STATSFILE=${BAM%%.bam}.stats.txt

   "samtools stats $BAM > $STATSFILE"

done
