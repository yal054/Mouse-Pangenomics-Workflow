# Alignments & Metrics

## Index assemblies

- `indexing/bwa-index.sh`: template for indexing GRCm38 and mT2T fasta files for alignment using BWA
  - docker image: `ghcr.io/uclahs-cds/bwa-mem2:2.2.1_samtools-1.17`
- `indexing/giraffe-index-mm10-mT2T.sh`: create and index "flat" graphs containing only either GRCm38 or mT2T for alignment using giraffe
  - docker image: `quay.io/vgteam/vg:v1.61.0`
- NOTE: minigraph-cactus pipeline creates most (`.min` and `.dist`) indices needed to align to the Founders graph using giraffe
- `indexing/FP-personalization-haplotype-indexing.sh`: create a `.ri` index to increase `.gbwt` (containing stored haplotype paths) access speed and `.hapl` index needed to create per-sample personalized diploid graphs from the Founders graph for alignment using giraffe

## Preprocess raw data
- `raw_data_preprocessing/CC-real-WGS-raw-fastqc.sh`: run fastqc on the raw downloaded real WGS data for QC
  - docker image: `mgibio/fastqc:v0.12.1-noble`
- `raw_data_preprocessing/CC-real-WGS-raw-fastp.sh`: run fastp to filter/QC data (deduplicae, remove retained adapters, check for overrepresented sequences, etc)
  - docker image: `mgibio/fastp:v0.23.4-noble`
- `raw_data_preprocessing/extract-sim-WGS-params-from-bwa-mm10-aln-stats.sh`: calculate median insert size average and standard deviation from samtools stats metrics from bwa-mm10-aligned real data, to use as parameters for simulating reads
- `simulate-WGS.sh`: simulate WGS reads using `wgsim`
  - docker image: `zhengxu32/pan_qc:1.0.10`
  - usage: `bash simulate-WGS.sh $FASTA $OUTDIR 150 15 303 112`
    - final 4 params are read length, depth, insert size, and insert size std dev; final 2 were calculated using the above script

## Alignment, post-processing, metrics

NOTE: scripts are listed largely in the order in which they were run


- `bwa-align-sort-index-stats.sh`: template used to align real and simulated data to GRCm38 and mT2T using bwa, as well as sort, index, and calculate stats post-alignment with samtools
  - docker image: `ghcr.io/uclahs-cds/bwa-mem2:2.2.1_samtools-1.17`

- `real-bwa-post-align-add-rg-and-merge.sh`: real raw data were retrieved and bwa-aligned at the lane level; this script merges them at the sample level post-alignment and adds readgroups, which are required by several steps in the Deepvariant pipeline (see variant analysis section)
  - docker image: `ctomlins/samtools`

- `real-bwa-align-post-merge-stats.sh`: calculate stats on the post-alignment sample-merged BAMs
  - docker image: `ghcr.io/uclahs-cds/bwa-mem2:2.2.1_samtools-1.17`


- `real-giraffe-pre-align-merge.sh`: merge the lane level real data by sample prior to alignments, mostly to ensure proper personalization for Founder graph alignments
  - Usage: `bash real-giraffe-pre-align-merge.sh $SAMPLE $LIST_DIR $OUT_DIR`
    - `$LIST_DIR` should contain two files, `${SAMPLE}_R1.list` and `${SAMPLE}_R2.list`, listing the R1 and R2 fastqs to merge

- `indexing/count_kmers.sh`: template command used to count kmers in the sample-merged real data and simulated data; kmers counts are used to create per-sample personalized diploid graphs from the Founders graph for alignment
  - docker image: `quay.io/biocontainers/kmc:3.2.4--haf24da9_3`
  - `$INPUT_FASTQ_PATHS` should contain the paths to the fastq files from which to calculate kmer counts, one per line

- `giraffe-flat-align-stats-surject.sh`: template used to align real and simulated data to "flat" graphs consisting solely of either GRCm38 or mT2T using vg giraffe, calculate stats with vg stats, and "surject" to BAM format
  - docker image: `quay.io/vgteam/vg:v1.61.0`

- `giraffe-Founders-personalize-align-stats-surject.sh`: template used to align real and simulated data to the Founders-derived personalized diploid graphs, calculate stats with vg stats, and surject to mm10-relative BAMs
  - docker image: `quay.io/vgteam/vg:v1.61.0`
  - `mm10_paths.txt`: contains all mm10 paths in the graph; passed to `vg surject` to provide candidate paths for surjection


- `custom-stats-bwa.sh`: template used to calculate custom (not calculate by samtools stats) metrics from bwa mm10/mT2T alignments
  - docker image: `ctomlins/samtools`
- `postprocess-giraffe-alns-and-custom-stats.sh`: template used to postprocess and calculate custom metrics from surjected giraffe "flat" mm10/mT2T and Founders alignments. Postprocessing includes stripping graph-standard PanSN name prefixes from chromosome names (no effect on the flat alignments), sorting, and `calmd` to calculate tags necessary for the custom stats command which are not produced by `vg surject`.
  - docker image: `ctomlins/samtools`
- `custom-stats-script.sh`: used by both of the above scripts to collect some metrics calculated by samtools, as well as parse alignment files to calculate some additional metrics (mapq60, gapless, and perfect counts)

- `add-readgroups-to-real-surjected-postprocessed-Founders-alns.sh`: add readgroups to surjected, post-processed (see above), vg-giraffe-aligned real data (sample merged prior to alignment), for use in the Deepvariant pipeline (see variant analysis section)
  - docker image: `ctomlins/samtools`
  - also indexed with `samtools index $BAM`
- `add-rgs-to-sim-bwa-mm10-alns.sh`: add readgroups to simulated data aligned to mm10 by bwa; intended to allow identification of read origin in synthetic in-silico diploid alignments created for reference bias analysis (see reference bias section)
  - docker image: `ctomlins/samtools`
- `add-rgs-to-sim-giraffe-Founders-alns.sh`: add readgroups to surjected, post-processed (see above), vg-giraffe-aligned simulated data; also intended for reference bias
  - docker image: `ctomlins/samtools`
