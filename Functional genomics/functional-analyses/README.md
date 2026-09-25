# Functional genomics

Applications of the pangenome to DNA methylation, allele-specific expression,
and regulatory variation.

The ATAC-seq analysis and the wet-lab protocols were done by co-authors.

## Methylation (`Methylation/`)

WGBS reads aligned to the Founder Pangenome with methylGrapher, compared against
Bismark alignment to linear references.

- `Download_Bismark_data.md`: retrieve the Bismark-aligned libraries
- `Download_methylGrapher_graph_results_v2_FullGraph_mq10.md`: retrieve the
  methylGrapher graph results
- `Surject_methylation_calls_v2_FullGraph_mq10.md`: surject graph-space
  methylation calls to linear coordinates, filtered at MapQ > 10
- `Liftover_Methylation_Calls.md`: lift CAST-coordinate calls onto mT2T and
  merge the per-library call sets
- `Analyze_Surjected_WGBS_DMR__CAST-Yu_vs_CAST-pg.Rmd`: differential
  methylation, CAST against Yu-T2T versus CAST against the pangenome
- `Per_Chromosome_Ixchel_Process_CC_graph.md`: split the CC graph per chromosome
  and convert it to the rGFA and annotation formats the graph browser needs
  for the graph-space methylation view
- `Run_RepeatMasker_on_CAST_T2T.md` and `Run_RepeatMasker_on_mT2T-Y.md`: repeat
  annotation for the browser tracks and the TE-subfamily context

## Allele-specific expression (`ASE/`)

rpvg haplotype-specific transcript quantification in CC032 x CC072 F1 liver.

- `F1_RPVG_ASE_analysis_summary.md`: the written summary of the call set, the
  concordance taxonomy, genome-wide discordance rates, enrichment results, an
  imprinted-gene check, and unresolved issues. Read this before the Rmds
- `HST_mosaic_concordance.Rmd`: QC of the haplotype assignment. Does the
  rpvg-selected haplotype-specific transcript agree with the parental mosaic?
  Gives the Max Haplotyping Probability distribution, the 0.9 retention
  threshold, between-replicate agreement, and the TPM difference ratio
- `Compare_to_ASA_v2.Rmd`: ASE tested with DESeq2 and compared against
  allele-specific accessibility
- `Svenson_DO_HFD.Rmd`: cross-cohort corroboration against the Svenson DO/HFD
  QTL Viewer data, giving the Abcc6 expression and protein QTL

## Regulatory variation (`Regulatory-variation/`)

Variant content of candidate cis-regulatory elements.

- `Annotate_Yu_T2T_with_cCREs.md`: lift the ENCODE mm10 cCRE annotation onto
  Yu-T2T, producing the cCRE input the other analyses use
- `Intersect_Variants_with_cCREs.md`: intersect the deconstructed graph variants
  with that annotation
- `Intersect_Variants_with_cCREs.Rmd`: per-element mutational burden, as variant
  events per 300 bp of element width, and unique cCRE counts by cCRE class and
  variant class
- `run_HOMER_on_All_variable_cCREs.md` and `HOMER_on_All_variable_cCREs_stats.Rmd`:
  motif analysis over the variable cCREs
