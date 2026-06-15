NUM_PROCESSORS=44

vg index --progress \
--threads ${NUM_PROCESSORS} \
--temp-dir ${TMPDIR} \
-x Founders-spliced-pangenome.xg \
Founders-spliced-pangenome.pg"
