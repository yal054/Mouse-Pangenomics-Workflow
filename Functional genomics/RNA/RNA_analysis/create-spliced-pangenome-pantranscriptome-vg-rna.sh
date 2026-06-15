NUM_PROCESSORS=36

vg rna --progress --threads ${NUM_PROCESSORS} \
--transcripts fixed.gtf \
--gbwt-bidirectional \
--write-gbwt Founders-pantranscriptome.gbwt \
--write-info Founders-pantranscriptome-info.tsv \
--gbz-format Founders-pangenome.gbz \
> Founders-spliced-pangenome.pg
