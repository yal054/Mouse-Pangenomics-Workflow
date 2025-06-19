`deconstruct-F1s.sh`: decompose the graph into a VCF of variants relative to a specified reference
- `--path-prefix mm10`: prefix for the reference paths (mm10 contigs in thise case) to be used as the VCF reference

`create-truth-sets-from-deconstructed-vcfs.sh`: process deconstructed VCF into a truth set of sites at which to examine reference bias using mpileup results
- `sed 's/mm10#0#//g'`: drop graph name prefix (PanSN) from chromosome names
- `--output-type v`: output uncompressed vcf (since next step is text stream processing)
- `--samples ^GRCm39` exclude GRCm39 from the vcf
- `-` use stdin as input
- `grep`: exclude uninformative sites from the vcf
- `--output-type u` output uncompressed bcf (most efficient stream when piping to another step that can process this format)
- `--multiallelics -`: split multiallelic sites into biallelic records
- `-f GRCm38.p6.renamed.filtered.fa`: provided fasta reference for left-alignment and normalization
- `-T $TMP-XXXXXX`: temporary directory to use for sorting; note that the `-XXXXXX` is detected by bcftools and causes it to make a unique directory name on each invocation

`make_diploid_alignments.sh`: for cohorts that were aligned as haploid reads, merge the haploid alignments into diploid alignments
- `ln`: for an alignment file aln.bam, some tools expect the index to be aln.bam.bai, and some expect aln.bai, so we make both

`alignment_mpileups.sh`: calculate mpileups from alignments, normalize, sort, and index
- `--gvcf 1`: output a gvcf; more efficient since it collapses runs of homozygous reference sites into blocks
- `--no-BAQ`: Disable probabilistic realignment for the computation of base alignment quality; only used for simulated data, since it was simulated with no errors
- see `create-truth-sets-from-deconstructed-vcfs.sh` for description of shared bcftools arguments

`mpileups_truth_set_isec.sh`: extract records from the mpileup where the truth set also has a record at this position, regardless of variant type
- `-n=2`: output positions present in 2/both of the provided files (in our case, there are only 2 files)
- `-w1`: output a single file
- `-c all`: collapse all sites with matching positions
