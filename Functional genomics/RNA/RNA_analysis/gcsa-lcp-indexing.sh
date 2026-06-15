MEM_LIMIT=1950
NUM_PROCESSORS=44

vg index -p -t ${NUM_PROCESSORS} \
-b /scratch1/fs1/hprc/johnegarza/gcsa \
-Y ${MEM_LIMIT} -Z 8192 \
-g Founders-spliced-pangenome.pruned.d32.k36.gcsa \
-f Founders-spliced-pangenome.d32.k36.nodes \
Founders-spliced-pangenome.d32.k36.pg"
