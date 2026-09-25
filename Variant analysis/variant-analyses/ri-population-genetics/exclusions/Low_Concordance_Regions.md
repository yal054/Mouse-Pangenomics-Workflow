# Genomic features at personalization mismatch sites

Characterizes what the sites where personalization disagrees with the expected
mosaic are made of: variant type, founder allele ambiguity, and repeat
content.

Methods support for the exclusion regions; see
[Exclusion_Annotations.md](Exclusion_Annotations.md).

## Background
Pangenome personalization of 40 CC RI lines achieves ~95.68% concordance with Srivastava
mosaic haplotype expectations (99.13% excluding ambiguous mosaic boundary regions). The
existing concordance output is aggregated by chrom × expected_founder_pair × outcome; no coordinate-level data exist for failure sites. This analysis generates position-level
mismatch data pooled across all 40 RI lines and tests enrichment of genomic features at
failure (Mismatch) vs. success (Match) sites.

**Features tested:**
- Variant type (SNP / INS / DEL / MNP / MULTIALLELIC)
- Founder allele ambiguity (how many of 8 founders carry a non-ref allele)
- RepeatMasker content (HOMER mm10 annotation)

---

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `VCF` | deconstructed VCF, contig prefixes stripped (~16 GB, ~41M lines, `FORMAT=GT` only) |
| `HAPL_DIR` | mosaic haplotype files, one `CC*.hap` per RI line (40 files) |
| `SAMPLE_LIST` | `personalized_samples.txt`, the 40 line names |
| `RMSK` | HOMER mm10 repeat annotation (~5.1M lines) |
| `EXTRACT_PY` | `extract_mismatch_sites.py`, in this directory |

```bash
WORKDIR=/path/to/Low_Concordance_Regions
VCF=/path/to/founder.plus_allCC.deconstruct.mm10.noprefix.vcf
HAPL_DIR=/path/to/mosaic_haplotypes
SAMPLE_LIST=/path/to/personalized_samples.txt
RMSK=/path/to/homer/genomes/mm10/mm10.repeats
EXTRACT_PY=extract_mismatch_sites.py
```

The RepeatMasker table format is
`repeat_name|class|family  chrom  start  end  strand ...`.

---

## Step 1: Document script
```bash
cd "$WORKDIR"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh python/si3fu6h )   # python 3.7.3 (build hash si3fu6h)

python3 "$EXTRACT_PY" --help
```

## Step 2: Build samples.tsv
```bash
cd "$WORKDIR"

HAPL_DIR="$HAPL_DIR"

awk -v dir="$HAPL_DIR" 'BEGIN{OFS="\t"}{print $1, dir"/"$1".hap"}' \
  "$SAMPLE_LIST" \
  > samples.tsv

wc -l samples.tsv && head -3 samples.tsv
```
```bash
# Verify all hapl files exist
awk '{print $2}' samples.tsv | while read f; do [ -f "$f" ] || echo "MISSING: $f"; done && echo "All hapl files present"
```

## Step 3: Submit extraction job
```bash
cd "$WORKDIR"

mkdir -p Logs

sbatch run_extract_mismatch_sites.sh
```

## Step 4: Validate output
```bash
cd "$WORKDIR"

wc -l mismatch_sites.tsv
head -3 mismatch_sites.tsv
```
```bash
# Sanity: total mismatch rate should be ~4.32%
awk 'NR>1{m+=$9; tot+=$8} END{printf "Mismatch rate: %.4f%%\n", m/tot*100}' mismatch_sites.tsv
```
```bash
# Sanity: columns sum correctly (n_inside = n_mismatch + n_match + n_missing_*)
awk 'NR>1{ok=($8==$9+$10+$11+$12+$13)?"OK":"FAIL"; if(ok=="FAIL") print NR, $0}' \
  mismatch_sites.tsv | head
```

## Step 5: Cleanup
```bash
cd "$WORKDIR"

mkdir -p Parameters
cp samples.tsv Parameters/
mv Logs/extract_mismatch_*.out Logs/
```

---

## Step 5b: Mismatch rate among called sites
```bash
cd "$WORKDIR"

wc -l mismatch_sites.tsv
head -3 mismatch_sites.tsv
```
```bash
awk 'NR>1{m+=$9; tot+=($9+$10)} END{printf "Mismatch/(Match+Mismatch): %.4f%%\n", m/tot*100}' mismatch_sites.tsv
```
The concordance pipeline (autosomes only) gives 0.81%. The 0.0209% difference is sex-chromosome mismatches, which this calculation includes and the Rmd filter excludes.

## Step 6: Build BED files
Full annotated BED files (with ref/alt_str for archive) + minimal BEDs for bedtools.
```bash
cd "$WORKDIR"

# Full annotated BED: chrom start end ref alt_str var_type n_founders_nonref n_mismatch n_match
awk 'BEGIN{OFS="\t"} NR>1 && $9>0 && $1~/^chr[0-9]+$/ {print $1,$2,$3,$4,$5,$6,$7,$9,$10}' \
  mismatch_sites.tsv > mismatch_sites_annotated.bed

awk 'BEGIN{OFS="\t"} NR>1 && $9==0 && $10>0 && $1~/^chr[0-9]+$/ {print $1,$2,$3,$4,$5,$6,$7,$9,$10}' \
  mismatch_sites.tsv > match_sites_annotated.bed

# Minimal BED (for bedtools): chrom start end var_type n_founders_nonref n_mismatch n_match
awk 'BEGIN{OFS="\t"}{print $1,$2,$3,$6,$7,$8,$9}' mismatch_sites_annotated.bed > mismatch_sites.bed
awk 'BEGIN{OFS="\t"}{print $1,$2,$3,$6,$7,$8,$9}' match_sites_annotated.bed > match_sites.bed

# Verify: 7 fields, n_mismatch before n_match
head -3 mismatch_sites.bed | awk '{print NF, $0}'
```

## Step 7: Convert RepeatMasker to BED
HOMER format: `name|class|family  chrom  start  end  strand ...` (0-based coords confirmed by consecutive intervals sharing endpoints).
```bash
cd "$WORKDIR"

awk 'BEGIN{OFS="\t"}{split($1,a,"|"); print $2, $3, $4, a[1], a[2], a[3]}' \
  "$RMSK" > mm10_rmsk.bed
```

## Step 8: Intersect with RepeatMasker (SBATCH)
Output cols: chrom start end var_type n_founders_nonref n_mismatch n_match rmsk_chrom rmsk_start rmsk_end repeat_name repeat_class repeat_family
("." in rmsk columns when no overlap, bedtools -loj)
```bash
cd "$WORKDIR"

sbatch run_bedtools_intersect.sh
```
```bash
cd "$WORKDIR"

wc -l mismatch_rmsk.bed match_rmsk.bed
head -3 mismatch_rmsk.bed
awk '$8=="."' mismatch_rmsk.bed | head -2
```
mismatch_rmsk.bed has more rows than mismatch sites (2,773,925 > 2,343,370) because -loj emits one row per overlapping repeat; sites with no overlap get a single "." row. 13 columns confirmed.


---

## Results

### Variant type (strongest signal)
| var_type | OR |
|---|---|
| MULTIALLELIC | 9.02 |
| INS | 1.30 |
| SNP | 0.24 |
MULTIALLELIC variants are strongly enriched and SNPs depleted; SNPs in unique sequence personalize almost perfectly.

### Founder allele ambiguity
Median n_founders_nonref = 3 at mismatch sites vs. 1 at match sites (Wilcoxon p ≈ 0). When many founders share a non-ref allele, the tool cannot confidently assign the correct haplotype.

### Repeat content (secondary)
61% of mismatch sites overlap RepeatMasker elements vs. 47% of match sites (OR = 1.80).
Enriched classes: simple repeats (OR = 5.81), low-complexity (OR = 2.38), satellites (OR = 2.34).
Depleted: LINEs, SINEs, LTRs, DNA transposons (OR 0.72–0.83).

### Mechanistic interpretation
Simple repeats, satellites, and low-complexity sequences are copy-number variable across haplotypes. In the vg deconstruct VCF these regions collapse into complex MULTIALLELIC records where multiple founders carry distinct alleles, creating both ambiguous variant representation and noisy read alignment. Mismatch burden is not random; it is concentrated in a structurally difficult, repeat-dense subset of sites where founder allele ambiguity is inherently high.

