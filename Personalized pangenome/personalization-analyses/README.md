# Personalized pangenome

Construction and validation of personalized diploid genome representations from
the Founder Pangenome, for 40 CC recombinant inbred lines and 10 Diversity
Outbred animals.

Personalization (`vg haplotypes` run against the Founder Pangenome) was done by
Q. Fu. These protocols start from its output.

## Building the CC Pangenome

- `Merge_personalized_walks_into_full_graph.md`: merge the per-sample
  personalized traversals with the founder GBWT, build the combined GBZ, and
  deconstruct it to a VCF in GRCm38 coordinates, producing the CC Pangenome
- `CC_genotype_comparison_to_muga_array.md`: why the merge is necessary. A
  personalized graph deconstructed on its own does not share variant sites
  with the founder graph, because sampling changes which subgraphs are snarls
- `split_cc_haplotypes.py`: split the diploid CC RI genotypes in the
  deconstructed VCF into separate haplotype columns
- `make_homozygous_diploid_vcf.py`: convert haploid founder genotypes to
  homozygous diploid calls so founders and RI lines can sit in one VCF

## Concordance against the expected mosaic

The published mosaic haplotypes (Srivastava et al. 2017) are the truth set.
Where a region is assigned a founder diplotype, the alleles of those founders
over that region are what personalization should have picked.

- `Compare_personalized_paths_to_mosaic_expectations.md`: score every variant
  site against the expected diplotype across all 40 lines
- `score_mosaic_concordance.py`: the scorer. Classifies each site as matched,
  mismatched, missing, or outside an assigned interval
- `run_Batch_score_mosaic_concordance.sh`: array wrapper for the above
- `Visualize_Concordance_Results_norm.Rmd`: the concordance matrix keyed by
  expected diplotype, plus the per-line concordance histogram
- `Visualize_Concordance_Results_Per_Site_Summary.Rmd`: per-site rather than
  per-line, identifying recurrently discordant positions

The `_norm` visualization works on the vcfbub-normalized VCF.

## Phasing (`phasing/`)

`vg haplotypes` is phase-concordant only within 10 kb intervals, so the
traversals were phased with a trained local-ancestry model before visualization.

- `Gnomix_CC_RI_Phasing.md`: train Gnomix on the eight founders as reference
  populations, then phase all 20 chromosomes with Gnofix
- `convert_qtl2_maps_to_gnomix.py`: convert R/qtl2 MMnGM genetic maps (mm10) to
  Gnomix `.gmap` format
- `convert_haploid_to_diploid_vcf.py`: make the haploid founder panel diploid,
  which Gnomix requires of a reference panel
- `hap_block_lengths.py`: haplotype block length distribution from the `.hap`
  files
- `Compare_phased_personalized_paths_to_mosaic_expectations__chr19.{md,Rmd}`:
  the phased chr19 view of CC010 against its expected mosaic

## Saturation (`saturation/`)

Sequencing depth needed for haplotype reconstruction.

- `Downsample_RI_data.md`: downsample the RI libraries from a mean 41.1x
- `Personalize_downsampled_RI_WGS.md`: re-run personalization at each depth
- `Merge_Saturation_personalized_walks_into_full_graph.md`: merge and
  deconstruct the downsampled traversals
- `Visualize_Concordance_Results.Rmd`: concordance as a function of depth

## Diversity Outbred (`diversity-outbred/`)

DO animals carry finely recombined mosaics and higher heterozygosity, and have
no published mosaic to score against. Reproducibility between paired low- and
high-coverage libraries of the same animal is used instead.

- `Download_and_personalized_with_lc_DO_WGS.md`: the low-coverage (1-5x) arm,
  covering retrieval, QC, adapter trimming, k-mer counting and personalization
- `Download_and_personalized_with_hc_DO_WGS.md`: the high-coverage (30-60x) arm
- `Merge_DO_{lcWGS,hcWGS}_personalized_walks_into_full_graph.md`: per-arm GBWT
  extraction and chunked merge
- `Merge_DO_combined_into_full_graph.md`: combine both arms with the founder
  GBWT into one GBZ
- `Merge_lc_and_hc_personalization.md`: build that GBZ and fix the chromosome
  naming in the deconstructed VCF
- `Compare_personalized_paths_between_coverage_levels.md`: per-site allele
  comparison between the paired libraries, with three null sets
- `Per_site_concordance_rate.Rmd`: the site-sharing rate between paired
  libraries

Population-structure and kinship estimates (PLINK, KING) are not used for the
DO comparison: at low coverage, sites with no read support still get allele
assignments, which distorts heterozygosity and makes the kinship estimates
uninterpretable.
