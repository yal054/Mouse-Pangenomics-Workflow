MEM_LIMIT=800
NUM_PROCESSORS=44

vg prune -p -t ${NUM_PROCESSORS} \
-M 32 \
-k 36 \
-u -g Founders-pantranscriptome.gbwt -m Founders-spliced-pangenome.d32.k36.nodes \
Founders-spliced-pangenome.pg \
> Founders-spliced-pangenome.d32.k36.pg"
