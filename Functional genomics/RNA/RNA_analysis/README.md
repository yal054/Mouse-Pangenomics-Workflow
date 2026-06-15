# RNA analysis

## Construction of spliced pangenome graph and pantranscriptome

### Graph input pre-processing

- `reformat-mT2T-from-mm10-liftover-annotations-gtf.sh`: used to sanitize and normalize GRCm38 -> mT2T lifted-over annotations. Standardize chromosome names to match graph naming conventions, normalize whitespace, etc.
- `reorder-negative-exons.py`: re-sort minus-strand exons into ascending genomic coordinate order
  - Usage: `python3 Mus_musculus.mhaESC_v1.1_with_mT2T-Y_v1.0.250617.graphpaths.tx.fixed.gtf FP-vg-rna-ready.gtf`

### Graph construction & indexing

All of the following scripts were run within docker image `quay.io/vgteam/vg:v1.60.0`, with the exception of pruning and GCSA indexing. These were run within `johnegarza/vg:1.60.0-expose-gcsa-mem`; this includes a patch that allowed us to increase the memory limit to take full advantage of our hardware while running this very resource-intensive step.

- `create-spliced-pangenome-pantranscriptome-vg-rna.sh`: main spliced pangenome/pantranscriptome construction script
- `prune-spliced-pangenome-for-gcsa-lcp-indexing.sh`: create a pruned spliced pangenome with lower complexity, in order to reduce the memory requirements for the already intensive GCSA & LCP index construction step
- `gcsa-lcp-indexing.sh`: create GCSA and LCP indices from the spliced graph
- `xg-index.sh`: create xg index from the spliced graph
- `dist-index.sh`: create dist index from the spliced graph
- `gbwt-ri-index.sh`: create GBWT `.ri` index from the spliced pantranscriptome

## Main analysis

### Raw read preprocessing

- `RNA-raw-fastqc.sh`: template used to run `fastqc` on raw data
  - docker image: `mgibio/fastqc:v0.12.1-noble`
- `RNA-raw-fastp.sh`: template used to run `fastp` on raw data
  - docker image: `mgibio/fastp:v0.23.4-noble`

- `align-RNA-mpmap.sh`: template command for aligning RNA-seq reads (paired fastq files) to the spliced pangenome/pantranscriptome using `vg mpmap`.
  - docker image: `quay.io/vgteam/vg:v1.60.0`
- `calculate-abundance-rpvg.sh`: template command for estimating transcript abundance from aligned reads using `rpvg`
  - docker image: `quay.io/jonassibbesen/rpvg`
