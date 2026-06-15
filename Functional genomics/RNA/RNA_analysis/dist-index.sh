MEM_LIMIT=512
NUM_PROCESSORS=44

vg index --progress \
--threads ${NUM_PROCESSORS} \
--temp-dir ${TMPDIR} \
-j Founders-spliced-pangenome.dist \
Founders-spliced-pangenome.pg
