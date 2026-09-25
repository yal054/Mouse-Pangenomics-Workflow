# Variant analysis

Variant content of the pangenome graphs, the genetic structure of the CC
recombinant inbred population, and variant-calling benchmarking.

## Per-bubble variant classes (`per-bubble-variant-classes/`)

Each non-overlapping variant site in the graph is a bubble. Every alternative
allele path is classified as SNV, INDEL or MNV, and sites are summarized by
class and by allele count. See `variant_classification.md` for what the classes
mean and how runs of `N` are handled.

- `Assign_Variant_Classes_Per_Bubble.py`: classify every ALT path of every
  bubble in a deconstructed VCF
- `Split_Multi_ALT_Per_Bubble.py`: explode multi-ALT sites to one row per
  alternative allele
- `run_Assign_Variant_Classes_Per_Bubble.sh`: batch wrapper
- `Calculate_per_bubble_stats_for_the_Founder_graph_from_deconstructed_graph.md`
  and the `_DMP_` equivalent: the protocols for each graph
- the matching `.Rmd` files: per-graph summaries covering variant class
  composition, ALTs per site, and upset plots
- `Calculate_per_bubble_stats_for__plot_Founder_and_DMP_together_for_panel.Rmd`:
  combines both graphs into the published panel
- `Visualize_deconstructed_{Founder,DMP}_stats.Rmd`: bcftools-stats summaries
  covering Ts/Tv, allele frequency, indel length and substitution types

## RI population genetics (`ri-population-genetics/`)

Classifies each site in the CC Pangenome by comparing the founder genotype
patterns against those of the 40 RI lines.

- `Compare_variants_in_deconstructed_graph_40_RI__NewRI__Norm.md`: the protocol.
  Split RI diplotypes, extract and process genotypes per chromosome, merge, then
  convert to presence/absence
- `prepare_for_genotype_upset.py`: build the presence/absence matrix the
  downstream analyses consume
- `merge_redundant_founders.py`: collapse the multiple assemblies of C57BL/6 and
  CAST/EiJ into one column each, so those strains are not over-weighted
- `Compare_variants_in_deconstructed_graph_40_RI.Rmd`: missingness,
  population-specific alleles, and how allele frequencies correspond between
  founders and RI lines
- `Analyze_Genotype_Matrices_deconstructed_graph_40_NewRI.Rmd`:
  identity-by-state between RI lines and each founder
- `Visualize_PCA_v1_Founder_40_New_RI.Rmd`: MDS of graph-derived genotypes

### Exclusions (`ri-population-genetics/exclusions/`)

Supplementary Note 3 excludes "variants in regions where personalization
performed unreliably". This folder defines those regions; the site
classification above depends on them.

- `Exclusion_Annotations.md`: the exclusion criteria and the resulting
  intervals: large bubbles (longest ALT over 100 kb) and low variant
  density (under 1,000 variants/Mb)
- `find_nonconcordant_sites.py` with `run_Batch_find_nonconcordant_sites.sh`:
  find sites where personalization disagrees with the expected mosaic
- `summarize_nonconcordance_sites.py`: per-site aggregation across animals
- `enrich_nonconcordance_bins.py`: test genomic bins for enrichment of
  non-concordant sites against a shuffled null
- `Visualize_nonconcordance_bin_enrichment.Rmd`: the bin-level enrichment result
- `Low_Concordance_Regions.md` with `extract_mismatch_sites.py`: characterize
  what mismatch sites are made of, by variant type, founder allele ambiguity and
  repeat content
- `Analyze_Low_Concordance_Regions.Rmd`: the resulting figures. Variant type is
  the dominant signal and repeat content is secondary

## Variant-calling benchmark (`variant-calling-benchmark/`)

DeepVariant calls against each reference, evaluated with `rtg vcfeval` against
truth sets derived from the personalized diploid graphs.

- `QC_and_filter_DV_variants.md`: QC of the DeepVariant callsets. The
  filtering thresholds described there were not applied; the benchmark runs
  on unfiltered callsets
- `Make_Challenging_regions_annotations.md`: build the challenging-region
  annotation used to stratify the evaluation
- `GQ20_DV-vcfeval.md`: the evaluation at a GQ20 threshold
- `GQ20_DV-vcfeval.Rmd`: ROC, F-measure, counts, and paired randomization tests
- `Visualize_QC_metrics.Rmd`: distributions of the per-variant QC metrics
- `Visualize_bcftools_stats_unfiltered.Rmd`: cross-sample bcftools-stats
  comparison of the unfiltered callsets
