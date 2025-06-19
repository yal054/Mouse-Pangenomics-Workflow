`fastqc.sh`: used to spot check WGS data prior to alignment
- `--memory 10000`: requested memory in kb
- `-o fastqc-WSB_EiJ`: directory for output report

`fastp.sh`: used to QC WGS sequencing following fastqc report
- `--verbose`: verbosely log activity while running
- `--dedup`: remove duplicated reads
- `--overrepresentation_analysis`: check for overrepresented sequences while running and include results in final report
- `--detect_adapter_for_pe`: necessary to check for and remove adapters for paired-end data

`seqtk-downsample-to-30x.sh`: used to downsample all data (~100x for simulated reads, variable for real WGS reads) to ~30x coverage
- `-s 11`: seed for RNG
- `0.645`: downsampling ratio

`make_pair_diploid_references.sh`: used to merge two assemblies into a diploid reference assembly
- `sed 's/^>/>$SAMPLE./'`: used to add a prefix indicating the originating sample to each sequence in the new diploid fasta
- `echo`: creates a newline between the last sequence from the first fasta and the first sequence from the second fasta

`bwa_index_assemblies.sh`: index assemblies for bwa-mem2 alignment

`bwa-align-and-postprocess.sh`: align reads to a given assembly using bwa-mem2, then sort and index the output BAM alignment file
- `-t 16`: number of threads to use for alignment
- `-@ 4`: number of threads to use for sorting
- `-T $TMP`: directory for temp files created while sorting
- `-O bam`: set output format to BAM
- `ln`: for an alignment file aln.bam, some tools expect the index to be aln.bam.bai, and some expect aln.bai, so we make both

`graph-align-stats-surject.sh`: pipeline for graphs which do not require sampling/personalization and can be directly aligned to (F1s): align, calculate alignment statistics, and surject to mm10/GRCm38 coordinates
- `-p`: log progress while running
- `-t 16`: use 16 threads for alignment
- `-N PWK_PhJ`: set sample name 
- `-o gam`: set output format to GAM
- `-p 16`: use 16 threads for calculating statistics
- `--interleaved`: indicate that input alignment to be surjected is paired-end data interleaved into a single file
- `--into-paths`: reference paths that aligned reads should be surjected to
- `--xg-name`: graph to which input was aligned to and to be used for surjection

`create_diploid_reads_helper.sh`: driver script for the script that merges unaligned reads to create in silico crosses for diploid alignment
- see [Graph README](../Genome-graph construction/README.md) for crosses that would be included in `crosses.tsv`

`add_sample_prefix_and_combine_pair.sh`: merge unaligned reads to create in silico crosses for diploid alignment
- `awk`: used to add prefix indicating original sample to each read in the resulting diploid fastq

`kmc_count_kmers.sh`: count kmers in unaligned reads
- `-k29`: set kmer size to 29 bp
- `-m16`: set memory to 16 GB
- `-okff`: set output format to .kff format
- `-t4`: request 4 threads
- `-hp`: hide percentage progress
- `@129S1_SvImJ-downsampled-fq-paths.txt`: file with input file paths
- `129S1_SvImJ-kmers`: path and prefix for the output file
- `$TMP`: path for temporary files; note that these files do not have unique names, so this should be unique to each invocation if running multiple instances in parallel

`129S1_SvImJ-downsampled-fq-paths.txt`: file with input file paths for kmc

`graph-sample-align-stats-surject.sh`: pipeline for graphs which do require sampling/personalization prior to alignment (CC, LTs): sample & create DPG, align, calculate alignment statistics, and surject to mm10/GRCm38 coordinates; see `graph-align-stats-surject.sh` description for information on shared parameters
- `--haplotype-name CC.hapl`: haplotype index file for graph from which to sample haplotypes to create personalized graph
- `--index-basename CC-v1F.diploid-sampled`: path and prefix for the personalized graph

`mm10_paths.txt`: file containing GRCm38/mm10 reference paths to which alignments should be surjected

`postprocess_surjections.sh`: rename graph sequence naming convention, sort, and index surjected alignments
- `-c \"sed 's/mm10#0#//g'\"`: command used to update header; this drops the prefix included as part of graph naming convention (PanSN), resulting in names like chr1 instead of mm10#0#chr1
- see `bwa-align-and-postprocess.sh` for explanation of samtools arguments
