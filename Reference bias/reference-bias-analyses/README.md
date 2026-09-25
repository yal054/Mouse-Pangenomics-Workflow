# Reference bias

Quantifies reference allele bias at heterozygous sites, comparing alignment to
GRCm38 against alignment to the Founder Pangenome. Runs on in-silico F1 crosses
between CC RI lines.

## The measurement

At a heterozygous site an unbiased aligner should recover the two alleles in
roughly equal proportion. Reference fraction is

```
reference_fraction = AD1 / (AD1 + AD2)
```

and the bias attributable to a reference is the shift in that fraction relative
to the pangenome:

```
delta(GRCm38) = RF_FP - RF_GRCm38
```

Sites count as strongly biased at reference-fraction thresholds from > 0.5 up to
> 0.9. A site counts as bias-corrected if it exceeds 0.7 on GRCm38 but falls
between 0.4 and 0.6 on the Founder Pangenome.

## Building the F1s

`Build_F1_Graphs_from_haploids.md` pairs RI haplotype graphs into in-silico
diploid F1 graphs: extract each line's GBWT, rename paths, merge, build the
combined GBZ, deconstruct to a VCF. These are the 20 F1 crosses everything else
here runs on, and the source of the Pkmyt1 browser example.

## Pileup parsing and per-site comparison

There are two parallel arms, simulated reads and real WGS. Files with `_Real` in
the name are the real-data arm; the others are simulated.

- `parse_ref_bias_vcf.py` and `run_Batch_parse_ref_bias_vcf.sh`: parse
  per-sample pileup VCFs into per-site allele depths
- `merge_parsed_ref_bias_vcf.py` and
  `run_Batch_merge_parsed_ref_bias_vcf__two-way-comparison.sh`: join the two
  references at each site to give paired reference fractions
- `Analyze_Reference_Bias_Pileups.md`: the simulated-data protocol
- `Analyze_Reference_Bias_Pileups_Real.md`: the real-data protocol

## ECDF construction and figures

- `process_vcf_to_ecdf.R`: reduce per-site reference fractions to empirical
  distribution functions
- `PreProcess_Reference_Alignment_Bias.Rmd` and its `_Real` counterpart: build
  and store the ECDF and EPDF objects
- `Visualize_Reference_Alignment_Bias.Rmd`: ECDF curves, counts of strongly
  biased sites by threshold across the 20 crosses, per-F1 fold reduction, and
  the paired Wilcoxon test comparing GRCm38 with the pangenome
- `Visualize_Reference_Alignment_Bias_Real.Rmd`: the real-data equivalent, with
  a randomization test on the maximum delta in cumulative fraction

## Genomic context of corrected sites

`Analyze_genomic_context_and_functional_associations_of_reference_alignment_bias_corrected_sites.md`
filters and merges the bias-corrected sites, then partitions them by how many of
the 20 crosses share each one. The matching `.Rmd` gives the gene and genomic
annotation composition of those sites: overall, split by degree of cross-sharing,
and per cross.
