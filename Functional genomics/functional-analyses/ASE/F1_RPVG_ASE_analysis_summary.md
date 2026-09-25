# F1 RPVG ASE analysis: summary

Analysis of allele-specific expression (ASE) in the F1 of CC032 × CC072
liver RNA-seq (samples **JJ013** and **JJ014**), using RPVG-selected
haplotype-specific transcripts (HSTs) against the CC-founder
pantranscriptome, followed by a DESeq2 ASE call and a full QC of the HST
selection against the CC032 / CC072 parental mosaics.

This is a summary of the analysis and its caveats, not a runnable protocol.
Read it before the `.Rmd` files in this directory.

## Inputs

| | |
|---|---|
| Cross | CC032 (♀) × CC072 (♂), F1 = 032x072_F19 (JJ013), 032x072_F20 (JJ014) |
| Tissue | mouse liver |
| Libraries | NovaSeq S4 PE100, 2 RNA-seq samples |
| RPVG outputs | `rpvg_outputs_ind_inf/JJ0{13,14}_S{53,54}_L004_joint.txt` |
| Pantranscriptome manifest | `Founders-pantranscriptome-info.tsv` (CC founders + B6 refs) |
| Parental mosaics | `CC032-GeniUncM1247_NYGC.hap`, `CC072-TauUncM3054_NYGC.hap` |
| GTF | `Mus_musculus.GRCm39.114.chr.gtf` |
| DO cohort for eQTL cross-check | `Svenson_DO_HFD.v12` (~478 mice, additive + diet_int + sex_int peaks) |

Analyses in this directory:

- [HST_mosaic_concordance.Rmd](HST_mosaic_concordance.Rmd): full taxonomy
  HST-to-mosaic QC across all expressed transcripts
- [Compare_to_ASA_v2.Rmd](Compare_to_ASA_v2.Rmd): DESeq2 ASE call, compared
  against allele-specific accessibility
- [Svenson_DO_HFD.Rmd](Svenson_DO_HFD.Rmd): DO founder-coefficient
  cross-check

## Filtering pipeline

1. **HST haplotyping probability ≥ 0.9** per transcript-cluster row.
2. **TPM_sum > 1** (both alleles summed).
3. **Present in both JJ013 and JJ014.**
4. **DESeq2 row-sum ≥ 10 reads** for testing.

Counts:

| Step | Transcripts | rows (tx × sample) |
|---|---:|---:|
| high-prob + TPM>1 (expressed universe) | 17,046 | 34,092 |
| DESeq2-tested (row-sum ≥ 10) | 7,747 | |
| **Significant ASE** (padj<0.05, \|LFC\|>1) | **906** | **1,812** |

The DESeq2 LFC sign is alphabetical: `allele_first = min(Name_1,Name_2)`
by label, `allele_second` = the other. `log2FoldChange > 0` means the
lexicographically-later haplotype has more reads. The sign carries no
parent-of-origin or founder-identity information; directional biology
requires re-anchoring to the parental mosaic.

## Gene-name annotation

`DESeq2_ASE_significant_lfc1_annotated.tsv`: 899 / 906 sig transcripts
mapped to a gene via GRCm39.114 GTF → **744 unique genes**. 877 protein-coding,
18 lncRNA, 3 TEC, 2 pseudogenes; 6 unmapped (likely retired Ensembl IDs).

Multi-isoform genes (≥3 sig ASE transcripts): *Gfm2*, *Dcaf11*, *Szrd1*,
*Syngr2* (4 each); *Hsd11b1*, *Slc17a4*, *Ptdss1*, *Fdft1*, *Etnk2*,
*Slc25a44*, *Srd5a3*, *Eci2*, *Hemk1*, *Nfia*, *Septin9* (3 each).

## HST selection vs parental mosaic: genome-wide QC

For each (transcript × sample) expressed row we compare the RPVG-selected
HST pair to the founder pair allowed by the CC032 and CC072 mosaics at the
transcript midpoint.

### Taxonomy (mutually exclusive, best → worst)

| pair_mode | group | meaning |
|---|---|---|
| `gold_unique_singleton` | concordant | each HST side maps to a single founder, pair ∈ mosaic-valid pairs |
| `strict_ambiguous_within_pair` | concordant | HST candidates ambiguous but all live inside the valid pair's founders |
| `permissive_with_extras` | concordant (soft) | valid pair can be reconstructed, but HST candidate union extends outside |
| `pool_but_no_cross_pair` | **discordant** | both HST sides in parental pool but no one-from-each-parent pair works |
| `one_side_off_mosaic` | **discordant** | one HST side has no founder overlap with either parent at this locus |
| `both_off_mosaic` | **discordant** | both HSTs have no founder overlap with either parent |

The three discordant modes are the complement of the permissive-pass
criterion; they are the hard-error set.

### Genome-wide rates (33,876 judgeable expressed rows, 16,938 transcripts)

| group | % |
|---|---:|
| concordant (gold + strict + soft) | **92.0** |
| gold_unique_singleton | 8.3 |
| strict_ambiguous_within_pair | 1.6 |
| permissive_with_extras | 82.0 |
| **discordant** | **8.0** |
| one_side_off_mosaic | 4.5 |
| pool_but_no_cross_pair | 2.7 |
| both_off_mosaic | 0.8 |

~92% of RPVG HST picks agree with the mosaic at permissive level
genome-wide. ~8% are hard errors, dominated by `one_side_off_mosaic`.

### What sits on the off-mosaic side

Founder enrichment on the off-mosaic side of `one_side_off_mosaic` rows vs
the genome-wide parental-pool baseline (fractional weighting):

| Founder | off-side % | pool baseline % | log2 enrichment | Fisher OR | FDR |
|---|---:|---:|---:|---:|---:|
| **PWK/PhJ** | 12.0 | 2.0 | **+2.35** | **6.88** | 10⁻²⁵ |
| **CAST/EiJ** | 15.9 | 5.5 | **+1.46** | **3.27** | 10⁻¹⁵ |
| WSB/EiJ | 17.5 | 10.1 | +0.76 | 1.88 | 10⁻⁶ |
| NOD/ShiLtJ | 15.2 | 13.5 | +0.16 | 1.14 | 0.35 |
| 129S1/SvImJ | 11.7 | 11.5 | +0.03 | 1.03 | 0.83 |
| A/J | 10.9 | 19.0 | −0.77 | 0.53 | 10⁻⁶ |
| NZO/HlLtJ | 8.3 | 16.5 | −0.95 | 0.45 | 10⁻⁷ |
| C57BL/6J | 8.4 | 22.0 | −1.33 | 0.33 | 10⁻¹⁴ |

The off-mosaic side is strongly **wild-derived-biased** (PWK, CAST, WSB
over-represented; classical lab strains depleted). In 83% of off-mosaic
rows, the off-mosaic HST carries the **minority of reads** (median 109 vs
370 for the in-mosaic side), i.e. it behaves as a read-assignment sink.

### Chromosomal distribution of discordance

`chr17` is a clear hotspot with markedly elevated local discordance rates,
consistent with the MHC region's complex haplotype diversity; chr4, 10,
16, 3 also show elevated local rates. See
`HST_discordance_by_chromosome.tsv`.

### Limits of the 8% discordance rate

The discordance test flags rows where the HST pair cannot be reconstructed
from our mosaic-based expectation. Three non-exclusive mechanisms can
produce this:

1. **RPVG HST mis-assignment** (picking an HST not present in either
   parent). The wild-derived-founder enrichment and minority-read signature
   support this as a contributor.
2. **Incomplete HST → founder assembly manifest**: a truly valid HST may
   not be linked to the expected founder's assembly in
   `Founders-pantranscriptome-info.tsv`.
3. **Mosaic segment-boundary imprecision** at transcript midpoints near
   `.hap` breakpoints.

The test cannot assign a cause per row; the genome-wide signatures describe
only the aggregate.

## Discordance is enriched in the ASE-significant subset

| | All expressed | Non-sig | **Sig-ASE** |
|---|---:|---:|---:|
| n rows | 33,876 | 32,076 | 1,800 |
| frac permissive-concordant | 92.0% | **93.1%** | **72.4%** |

Fisher OR sig vs non-sig (concordant vs discordant): **0.20** (95% CI
0.18–0.22), p ≈ 10⁻¹⁴⁴ → ~5× enrichment of hard errors among sig-ASE
rows. Mean HST candidate-union size is nearly identical between sig and
non-sig (4.48 vs 4.50), so ambiguity is not the driver; the HST pair
selected at sig-ASE loci is more often off-mosaic. A likely mechanism is that
RPVG assigns a spurious off-mosaic HST at loci where one parental HST carries
most reads, creating apparent allele imbalance that DESeq2 then calls
significant. The hard-error rows are used as a filter on the ASE call set.

## Biological signals: ORA

Foreground: ASE-significant genes. Background: DESeq2-tested genes (not
the expressed pool). WebGestaltR ORA.

### Original (all sig, FDR < 0.1)

| DB | Term | ER | FDR |
|---|---|---:|---:|
| GO MF | monooxygenase activity | 2.37 | 0.032 |
| GO BP | transition metal ion transport | 2.64 | 0.071 |
| GO BP | small molecule catabolic process | 1.77 | 0.071 |
| GO BP | drug catabolic process | 2.27 | 0.071 |
| KEGG | Steroid hormone biosynthesis | 2.29 | 0.080 |

### Concordant-only (sig-ASE ∩ both-sample permissive concordant: 559 genes vs 4,525)

| DB | Term | ER | FDR |
|---|---|---:|---:|
| KEGG | Steroid hormone biosynthesis | 2.62 | 0.062 |
| KEGG | **Chemical carcinogenesis** | 2.39 | 0.072 |
| KEGG | **Alzheimer disease (ETC/mito members)** | 2.25 | 0.072 |
| KEGG | **Peroxisome** | 2.61 | 0.072 |
| GO BP | small molecule catabolic process | 1.95 | 0.083 |
| GO BP | drug catabolic process | 2.57 | 0.083 |
| GO MF | monooxygenase activity | 2.54 | 0.085 |

The liver xenobiotic/Cyp module survives QC filtering and sharpens:
enrichment ratios rise and more pathways pass the cutoff. "Transition metal
ion transport" drops out, suggesting that signal was driven by the discordant
subset, possibly a chr17 / iron-handling artifact given the chr17 discordance
hotspot.

Terms found only in the concordant-only run:
- **Chemical carcinogenesis** (mmu05204), classic liver Cyp/GST module.
- **Peroxisome** (mmu04146), fatty-acid β-oxidation biology.
- **Alzheimer disease** (mmu05010), KEGG's AD pathway overlaps heavily
  with mitochondrial ETC; likely reflects ETC-member enrichment rather
  than AD biology. The gene list would confirm this.

## Locus-matched founder enrichment (ORA terms)

For each ORA-enriched term, observed founder mass (from HST candidate
sets) was compared to (a) a row-shuffled pool baseline and (b) the
mosaic-implied expected founder mass at that term's loci. After
accounting for the locus-specific mosaic expectation:

- PWK's apparent enrichment in drug catabolism is entirely a locus
  effect: CC032 × CC072 carries PWK at the hepatic Cyp cluster loci
  (obs=10 = mosaic=10), so it is not a founder-specific ASE signal.
- Residual (mosaic-corrected) signals that survive are modest: **NZO up
  in monooxygenase** (+0.65 vs mosaic), **129S1 up in metal-ion
  transport** (+1.19 vs mosaic; the term itself is suspect after QC), **A/J depleted in steroid biosynthesis** (−1.30), **CAST depleted
  in metal-ion transport** (−0.97).

Detail: `Founder_breakdown/`.

## Imprinted-gene sanity check

**Source:** [Geneimprint Mouse Imprinted Genes catalog](https://www.geneimprint.com/site/genes-by-species.Mus+musculus),
accessed 2026-04-21. 177 entries (143 `Status == "Imprinted"`, 2 `Tissue
Dependent`, the rest `Predicted` / `Conflicting Data` / `Not Imprinted` /
`Unknown`). Verbatim copy at
`Imprinted_check_Geneimprint/geneimprint_mouse_catalog_2026-04-21.tsv`.

162/177 Geneimprint symbols match a `gene_name` in the GRCm39.114 GTF;
**21 imprinted genes are present in the DESeq2-tested background pool**.
Most canonical large-effect imprinted genes (Igf2, H19, Mest, Peg3, Snrpn,
Meg3, Kcnq1ot1, Airn, Dlk1) are not in the tested pool; they likely fall
below the row-sum ≥ 10 cutoff or are not detected by RPVG's HST clustering
in these samples.

Overlap test:

| List | Size | In tested pool | In sig-ASE | OR | p (one-sided) |
|---|---:|---:|---:|---:|---:|
| Primary (Status = Imprinted) | 142 | 21 | 4 | 1.32 | 0.39 |
| Inclusive (+ Tissue Dependent) | 144 | 22 | 5 | 1.66 | 0.23 |

Imprinted genes are not significantly enriched in the sig-ASE set vs the
tested background. The hits:

| Gene | Geneimprint status | Expected allele | n sig-ASE rows | % concordant |
|---|---|---|---:|---:|
| *H13* | Imprinted | Maternal | 4 | 100 |
| *Pon3* | Imprinted | Maternal | 4 | 100 |
| *Maged2* | Imprinted | Maternal | 2 | 100 |
| *Ddc* | Imprinted | Paternal | 6 | 67 |
| *Igf2r* | Tissue Dependent | Maternal | 2 | 0 (chr17 hotspot, fails QC) |

The hits are individually plausible (four of five are well-known
maternally expressed imprinted genes, and most are mosaic-concordant), but
the population-level test is not significant. Two limitations contribute to
the modest signal: (1) classical high-effect imprinted genes (Igf2, H19, Mest,
Peg3, Snrpn) drop out of the tested pool, reducing power; (2) Igf2r, the
canonical tissue-dependent imprinted gene, fails HST-mosaic concordance,
consistent with the chr17 discordance hotspot. Both need follow-up.

## Cross-cohort validation: DO founder coefficients

From [Svenson_DO_HFD.Rmd](Svenson_DO_HFD.Rmd): each sig-ASE row that
uniquely resolved to a single oriented founder pair was compared to the
DO cohort's fitted founder coefficients at the transcript's gene-level
nearest marker. Sign concordance and correlation stratified by the
HST-mosaic concordance flag:

| Stratum | n rows | sign-concordance % | Pearson | Spearman |
|---|---:|---:|---:|---:|
| **gold_unique_singleton** | 144 | **72.2** | 0.255 | **0.347** |
| soft_concordant | 986 | 66.5 | 0.179 | 0.233 |

Gold rows (the cleanest HST picks) agree better with the independent
~478-mouse DO eQTL founder-coefficient signal than soft-concordant rows
do, which supports the QC from an unrelated cohort.

## Unresolved issues

1. **Igf2r / chr17 hotspot.** Chr17 has the highest local discordance
   rate genome-wide *and* contains the only canonical imprinted gene
   (Igf2r) that fails concordance. Likely a shared cause: MHC and
   surrounding regions have very complex haplotype diversity which
   RPVG's HST selection and/or the assembly manifest may not handle
   cleanly.
2. **Manifest completeness.** A non-trivial fraction of the 8% genome-wide
   discordance could be manifest-incompleteness rather than RPVG
   mis-assignment. Validating a random sample of "off-mosaic" HSTs
   against the source assemblies directly would separate (1) from (2) in
   the caveat list above.
3. **LFC directionality.** Any biological-direction analysis currently
   requires re-anchoring each transcript via the oriented-founder
   assignment step (see `oriented_assignments` in the mosaic-check
   files). The current DESeq2 `log2FoldChange` is lexicographic only.
4. **"Alzheimer disease" KEGG hit**: the pathway overlaps heavily with
   mitochondrial ETC members that also drive chemical-carcinogenesis
   and Cyp signals, so this is probably not AD biology. Pulling the gene
   list would confirm.

## Output files

Under `Analyze_F1_RPVG_data_exploration/` in the Box data directory:

### ASE call
- `DESeq2_ASE_results.txt`: all 7,747 tested transcripts
- `DESeq2_ASE_significant_lfc1.txt`: 906 sig at padj<0.05 & \|LFC\|>1
- `DESeq2_ASE_significant_lfc1_annotated.tsv`: with gene names + biotype

### Mosaic concordance QC
- `HST_concordance_full_taxonomy_per_row.tsv`: per-row pair_mode + side statuses
- `HST_concordance_headline_rates.tsv`: genome-wide rates
- `HST_pair_mode_overall.tsv`, `HST_pair_mode_by_sig.tsv`, `HST_pair_mode_fisher_sig_vs_nonsig.tsv`
- `HST_side_status_joint_all.tsv`
- `HST_discordance_by_chromosome.tsv`
- `HST_clean_transcripts_gold.tsv`: 1,374 transcripts that are gold in both samples
- `OffMosaic_drilldown/`: off-mosaic-side founder enrichment analysis

### Biological enrichment
- `ORA_WebGestaltR/`: original ORA (all-sig), FDR 0.05 and 0.10
- `ORA_WebGestaltR/Concordant_only/`: ORA on concordant sig-ASE subset
- `ORA_WebGestaltR/Founder_breakdown/`: locus-matched founder enrichment per term

### Imprinted check (Geneimprint)
- `Imprinted_check_Geneimprint/geneimprint_mouse_catalog_2026-04-21.tsv`: verbatim catalog
- `Imprinted_check_Geneimprint/imprinted_overlap_summary.tsv`: Fisher test results across list-definition choices
- `Imprinted_check_Geneimprint/imprinted_sig_ASE_per_row_Geneimprint.tsv`: per-row HST concordance for hits

Do not use the older `Imprinted_check/` directory: its hand-assembled gene
list miscounted the background pool.

### DO cross-cohort
- `ASE_vs_Predicted_Coefficient_Comparison.tsv` (from [Svenson_DO_HFD.Rmd](Svenson_DO_HFD.Rmd))
- `DO_coef_concordance_stratified/`: sign-concordance + correlation by
  HST concordance stratum
