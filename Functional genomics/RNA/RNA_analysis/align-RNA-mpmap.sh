NUM_PROCESSORS=32

vg mpmap -t $NUM_PROCESSORS \
-l short -n rna \
-x Founders-spliced-pangenome.xg \
-g Founders-spliced-pangenome.pruned.d32.k36.gcsa \
-d Founders-spliced-pangenome.dist \
-f $READ1 \
-f $READ2 \
> $OUTGAMP
