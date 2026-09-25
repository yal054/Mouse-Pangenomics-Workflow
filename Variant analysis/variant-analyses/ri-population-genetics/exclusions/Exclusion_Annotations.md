# Exclusion Annotations for Founder-Only Block Regions

Defines the genomic regions excluded from the RI population-genetic analysis.
Supplementary Note 3 refers to these as the regions "where personalization
performed unreliably".

The site classification in
`../Compare_variants_in_deconstructed_graph_40_RI__NewRI__Norm.md` is run after
these regions are removed. Without the exclusion, large artefactual
founder-only blocks on chr7, chr12 and chr14 dominate the result.

## Inputs

| Input | Description |
|---|---|
| Top-level deconstructed VCF (no `-a`) | source of both quantities below |
| Longest ALT length per site | criterion 1 |
| Record count per 1 Mb bin | criterion 2 |

## Outputs

| File | Contents |
|---|---|
| `large_bubble_exclusion__max_alt_len_gt_100kb.bed` | 184 regions, 143.0 Mb |
| `low_density_exclusion__lt_1000_variants_per_Mb.bed` | 19 merged regions, 151.0 Mb |
| `combined_exclusion__union.bed` | 188 regions, 207.1 Mb (8.4% of the autosomal genome) |

## Problem
When analyzing founder vs RI allele sharing from the deconstructed CC pangenome graph, large contiguous blocks on chr7 (3-31 Mb), chr12 (3-24 Mb, 88-113 Mb), and chr14 (3-44 Mb) show artificially elevated founder-only variant counts. These blocks are artifacts of graph complexity, not real biology.

## Root cause
The original `vg deconstruct` (without `-a -C` flags) represents these regions as single mega-snarls: individual VCF records spanning tens of megabases. When re-run with `-a` (all nesting levels) for vcfbub processing, nested sub-variants within these mega-snarls are unpacked. At the nested level, all 80 RI haplotypes (40 lines x 2) systematically carry the same allele (matching CAST or PWK), while most founders carry the reference allele. This produces a spurious founder-only signal.

Key evidence:
- The founder-only blocks are identical between the raw (`-a -C`) and vcfbub+norm VCFs; vcfbub does not create or modify them.
- The original deconstruct (no `-a`) has only 9 records spanning the entire chr7:3-31 Mb region, including one 28 Mb mega-bubble with 5/8 founders missing.
- In the clipped per-sample deconstruct (MC default clipping), chr14:7-18 Mb has ~8,000-12,000 variants/Mb, but the full graph deconstruct has zero, confirming these regions are unreliable in unclipped graphs.
- At decomposed sites, all 80 RI haplotypes match CAST at 99.4% of complete LV=0 sites in chr14:7-10 Mb (45,245 sites). This is biologically impossible for 40 independent RI lines.

## Exclusion criteria

### 1. Large bubble exclusion (`large_bubble_exclusion__max_alt_len_gt_100kb.bed`)
- **Criterion:** Sites whose longest ALT allele exceeds 100,000 bp in the top-level deconstructed VCF (no `-a`).
- **Source data:** the pre-normalization (no `-a`) deconstructed VCF
- **Interval definition:** POS to POS + length(REF) for each qualifying site.
- **Result:** 184 regions, 143.0 Mb.
- **Precedent:** vcfbub in the HPRC pangenome pipeline uses `-r 100000` to filter sites with REF alleles >100kb (Liao et al. 2023, Nature). This filter captures the equivalent regions from the graph metrics side.

### 2. Low variant density exclusion (`low_density_exclusion__lt_1000_variants_per_Mb.bed`)
- **Criterion:** 1 Mb bins with fewer than 1,000 top-level snarl variants in the deconstructed VCF (without `-a`). Genome-wide median is ~18,000 variants/Mb.
- **Source data:** the same VCF, counting records per 1 Mb bin.
- **Interval definition:** Adjacent qualifying bins merged into contiguous regions.
- **Result:** 19 merged regions, 151.0 Mb.
- **Rationale:** `vg haplotype` relies on graph-unique k-mers to assign sample walks through the graph. In regions with low variant density, there are fewer informative k-mers to distinguish between founder haplotypes. This causes RI walks to be incorrectly assigned, all converging on a single founder's path (e.g. CAST), producing spurious founder-only signal. This criterion captures chr14:3-44 Mb, which has no single mega-bubble but has near-zero top-level variant density and shows all 80 RI haplotypes matching CAST at 99.4% of sites.

### 3. Combined exclusion (`combined_exclusion__union.bed`)
- **Criterion:** Union of criteria 1 and 2.
- **Result:** 188 regions, 207.1 Mb (8.4% of autosomal genome).

## Supporting files
- `large_bubble_positions_with_ref_lengths.txt`: All 291 sites with `max_alt_len > 100,000`, with their REF allele lengths. Columns: chrom, pos, ref_length.
- `variant_density_per_1Mb_bin__all_autosomes.txt`: Variant count per 1 Mb bin for all autosomes, including zero-count bins. Columns: chrom, bin(Mb), count.
- `variant_density_per_1Mb_bin__nonzero_only.txt`: Same but only bins with >0 variants.

## Source VCFs
- **Original deconstructed VCF (no `-a -C`):** `founder.plus_allCC.deconstruct.mm10.vcf`, from the merge step
  - Command: `vg deconstruct --path-prefix mm10 -t 20 --verbose founder.plus_allCC.gbz`
  - Git commit: `a18afee9` (Mar 1 2026)
- **Re-deconstructed VCF (with `-a -C`):** `founder.plus_allCC.deconstruct.mm10.raw.vcf.gz` at same directory.
  - Command: `vg deconstruct -P mm10 -C -a -t 20 founder.plus_allCC.gbz`
  - Git commit: `93afa1db`
- **vcfbub+norm VCF:** `founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.gz` at same directory.
  - vcfbub: `-l 0 -r 100000`
  - bcftools norm: `-f mm10.fa`

## Key findings from investigation
1. The `-a` flag in `vg deconstruct` is required for vcfbub to function (vcfbub needs LV/PS tags from nested snarl decomposition). Adding `-a` unpacks nested variants inside mega-snarls that were previously opaque. This is what creates the founder-only blocks, not vcfbub itself.
2. These regions correspond to areas where MC clipping would normally remove problematic paths. The full (unclipped) graph retains complex topology that produces unreliable variant calls when decomposed.
3. Binned per-site metrics from the original VCF show these regions as empty, confirming they are represented by single mega-snarls with no internal structure visible at the top level.
