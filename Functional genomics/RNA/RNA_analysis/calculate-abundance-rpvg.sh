/usr/bin/rpvg -t 8 \
-g Founders-spliced-pangenome.xg \
-p Founders-pantranscriptome.gbwt \
-f Founders-pantranscriptome-info.tsv \
-a $GAMP \
-o $OUTDIR/$LABEL \
--ind-hap-inference \
-i haplotype-transcripts
