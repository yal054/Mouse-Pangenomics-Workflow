# Variant analysis

## Call variants

### Preprocess alignments for MGI Deepvariant pipeline

- `fix-surjected-chr-lens-launcher.sh`: due to clipping, chromosome lengths in the graph do not necessarily match those listed in an assembly's .fasta file, causing errors in the pipelines; this script updates lengths in BAM headers as needed
  - docker image: `ctomlins/samtools`
  - also indexed with `samtools index $BAM`
- `fix-surjected-chr-lens-script.sh`: called by the above script to extract fasta chromosome lengths
- `reorder-contigs-and-index.sh`: reorder BAM alignments so that chromosomes are listed in the same order as in the reference fasta
  - docker image: `mgibio/picard:v3.3.0-noble`

### Deepvariant pipeline

The MGI Deepvariant pipeline is available [here](https://github.com/twlab/cig-pipelines/blob/main/wdl/pipelines/genome/updated_wgs_from_bam.wdl)

## Comparison of BWA linear-native alignment variant calls vs `vg giraffe` surjected graph alignment variant calls

### Prepare RI line diploid haplotype blocks from mosaic files

[Mosaic files were obtained from UNC](https://csbio.unc.edu/CCstatus/CCGenomes/#founders)

- `parse_hapfiles.py`: remove blocks smaller than 1 Mbp, trim blocks to remove overlaps, and trim/split blocks so that all covered intervals consist of a pair of blocks with matching start and stop coordinates
  - Usage: `python parse_hapfiles.py $HAP_MOSAIC_FILE > $PARSED_OUTFILE`

### Prepare truth set VCFs

### Prepare master truth set

- `split-Founders-vcf-by-chromosome.sh`: split the mm10-reference VCF output by the minigraph-cactus pipeline by chromosome for better parallelism in the next steps
  - docker image: `staphb/bcftools:1.21`
- `per-chromosome-vcfwave.sh`: run `vcfwave` on the per-chromosome VCFs from above
  - docker image: `quay.io/comparative-genomics-toolkit/cactus:v2.9.7`
- `sort-per-chr-vcfwave-vcfs.sh`: sort the above VCFs
  - docker image: `staphb/bcftools:1.21`
- `merge-norm-sort-vcfwave-vcfs.sh`: merge all of the above VCFs, then normalize (part of post-vcfwave best practices) and sort
  - docker image: `staphb/bcftools:1.21`
- `vcfcreatemulti.sh`: re-create multiallelics (part of post-vcfwave best practices)
  - docker image: `quay.io/comparative-genomics-toolkit/cactus:v2.9.7`
- `sort-multi-vcf.sh`: sort the above VCF
  - docker image: `staphb/bcftools:1.21`
- `filter-non-biallelics.sh`: filter to retain only biallelic sites
  - docker image: `staphb/bcftools:1.21`
- `type-and-len-filter-biallelic-Founders-vcf.sh`: filter to retain only snps and indels, and remove any SVs (indels > 50 bp)
  - docker image: `staphb/bcftools:1.21`

#### Prepare per-RI truth sets

- `make_truth_set.py`: using haplotype block sample assignments and intervals, pull appropriate variants from the master truth set to make per-line truth sets
  - Usage: `python make_truth_set.py --truth-vcf $MASTER_TRUTHSET --blocks $SAMPLE_HAP_BLOCKFILE --output $SAMPLE_TRUTHSET_VCF`
- `subset-truthsets-by-repeatmasker.sh`: subset per-line truth sets into "easy" and "hard" regions, based on repeatmasker annotations
  - docker image: `staphb/bcftools`

### Subset & filter DV callsets
- `subset-callsets-to-hap-phased-target-regions.sh`: subset callsets to regions with diploid haplotype block assignments
  - docker image: `staphb/bcftools`
- `subset-callsets-by-repeatmasker.sh`: subset callsets into "easy" and "hard" regions, based on repeatmasker annotations
  - docker image: `staphb/bcftools`
- `filter-callsets-to-GQ20.sh`: filter out calls with GQ < 20
  - docker image: `staphb/bcftools`

### Compare callsets to truthsets using `vcfeval`
- `launch-vcfeval.sh`
  - docker image: `blcdsdockerregistry/rtg-tools:3.12`
