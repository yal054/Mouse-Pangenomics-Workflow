# Variant-calling evaluation with vcfeval

Evaluates DeepVariant calls made against GRCm38 versus against the Founder
Pangenome (with surjection to linear coordinates), using `rtg vcfeval` at a
GQ 20 threshold.

## The truth set

Per-RI-line truth sets are built from the vcfwave-decomposed VCF derived from
the Founder Pangenome, combined with the published founder haplotype mosaics:
where a region is assigned a founder diplotype, that founder's alleles over the
region are the expected calls.

The vcfwave decomposition comes from
`../../../Personalized pangenome/personalization-analyses/Merge_personalized_walks_into_full_graph.md`,
step 9.

## Inputs

| Variable | Description |
|---|---|
| `VCFEVAL_RESULTS` | `rtg vcfeval` output, one directory per condition |

```bash
VCFEVAL_RESULTS=/path/to/GQ20-filtered-vcfeval-results
```

The vcfeval runs were performed by a co-author; the `*.tsv.gz` ROC summaries
are the inputs consumed here.

## Conditions

| Condition | Reference |
|---|---|
| `linear.GQ20.DPnone` | GRCm38, BWA |
| `surjected.GQ20.DPnone` | Founder Pangenome, giraffe, surjected |

GQ 20 with no depth filter. The DeepVariant callsets themselves are unfiltered;
see `QC_and_filter_DV_variants.md`.

## Analysis

ROC curves, F-measure, per-condition call counts and paired randomization tests
are computed in `GQ20_DV-vcfeval.Rmd` from the `*.tsv.gz` ROC summaries.

## Stratification

Errors are stratified into easy and challenging regions using the annotation
built in `Make_Challenging_regions_annotations.md` (simple repeats, low
complexity, satellites and segmental duplications), and reported as stratified
error counts.
