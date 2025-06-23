# Personalized pangenome subgraphs


This directory contains helper scripts for building, validating, indexing, and analyzing mouse pangenome graphs and sequencing data. Each script includes usage instructions at its top.


- Prepare graph and WGS reads
  - **graph_index.sh**: Create index files.
  - **fastq_downsample.sh**: Randomly subsample paired-end FASTQ reads to a percentage.
  - **kmer_count.sh**: Count k-mers using KMC.
- **personalization.sh**: Extract a personalized subgraph based on sample VCF and realign reads.
- Building validation graph
  - **build_mc_graph.sh**: script for building minigraph-cactus graph
  - **build_validation_graph.sh**: The example script for calling **build_mc_graph.sh**


**Requirements**: VG, cactus container, Python 3

See each script’s header comments for detailed usage and options.