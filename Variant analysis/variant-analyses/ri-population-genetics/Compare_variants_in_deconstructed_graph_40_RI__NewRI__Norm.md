# Classify variants by founder / RI population

Classifies every site in the CC Pangenome by comparing the genotype patterns of
the eight founders against those of the 40 RI lines, and computes the
population structure from the resulting genotypes.

Operates on the vcfbub-normalized callset.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `VCF` | `founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.gz` |
| `SPLIT_PY` | `split_cc_haplotypes.py` |
| `UPSET_PY` | `prepare_for_genotype_upset.py` |
| `MERGE_PY` | `merge_redundant_founders.py` |
| `CAPTURE_BATCH` | `run_batch_analyze_variant_capture.sh` |

```bash
WORKDIR=/path/to/PCA_on_deconstructed_founder_40_RI_graph_Norm
VCF=/path/to/founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.gz
SPLIT_PY="../../../Personalized pangenome/personalization-analyses/split_cc_haplotypes.py"
UPSET_PY=prepare_for_genotype_upset.py
MERGE_PY=merge_redundant_founders.py
CAPTURE_BATCH=run_batch_analyze_variant_capture.sh
```

Run this after the exclusion regions are defined in `exclusions/`. The counts
in Supplementary Note 3 exclude those regions.

## Outputs

| File | Use |
|---|---|
| `Processed_variant_genotypes_simplified.txt` | per-site founder/RI classification |
| `variant_genotypes_presence_absence_counts.txt` | allele-pattern counts |
| `mds/all_crosses_mds.*` | MDS coordinates |

## 1. Split the RI diplotypes

The RI lines were personalized as diploids, so their genotypes are diploid while
the founders are haploid. Downstream processing expects one allele per column,
so each RI genotype is split into two fields.

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

ln -s "$VCF" .

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh python@3.7.3 )

python3 "$SPLIT_PY" \
  founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.gz \
  founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.splitdiplotype.vcf
```

## 2. Extract genotypes

```bash
cd "$WORKDIR"

eval $( spack load --sh bcftools/yz7hzwn )   # bcftools 1.12 (build hash yz7hzwn)

bcftools query -H -f '%CHROM\t%POS[\t%GT]\n' \
  founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.splitdiplotype.vcf \
| sed -E 's/\[[0-9]+\]//g; s/:GT//g' \
| sed '1s/^# //' \
> variant_genotypes.txt
```

## 3. Split by chromosome and classify

Only autosomes are processed. The RI lines are inbred and the sex-chromosome complement differs, so founder/RI allele
sharing is not comparable there.

```bash
cd "$WORKDIR"

for i in $(seq 1 19); do
    awk -v c="chr$i" 'NR==1 || $1==c' variant_genotypes.txt \
      > "variant_genotypes_chr${i}.txt"
done
```

`run_batch_analyze_variant_capture.sh` reads one line per autosome from
`process_genotypes_params.txt`, tab-separated:
`INPUT  OUTPUT`
`INPUT` is `variant_genotypes_chr<N>.txt` and `OUTPUT` is
`Processed_variant_genotypes_chr<N>.txt`. 19 lines, chr1-chr19.

```bash
cd "$WORKDIR"

# Resources used: 64 GB per task, 19 tasks (one per autosome)
sbatch --mem=64G --array=1-19%19 "$CAPTURE_BATCH" process_genotypes_params.txt
```

Merge the per-chromosome results, keeping one header:

```bash
cd "$WORKDIR"

cat Processed_variant_genotypes_chr*.txt > Processed_variant_genotypes.txt

head -n 1 Processed_variant_genotypes.txt > TEMP.txt
grep -v "CHROM" Processed_variant_genotypes.txt >> TEMP.txt
mv TEMP.txt Processed_variant_genotypes.txt
```

### Columns of the classification table

| # | Column | | # | Column |
|---|---|---|---|---|
| 1 | CHROM | | 14 | Both |
| 2 | POS | | 15 | RI_Only |
| 3 | Unique_Genotypes | | 16 | Founder_Only_Fraction |
| 4 | Founder_Count | | 17 | Both_Fraction |
| 5 | Founder_Count_Strict | | 18 | RI_Only_Fraction |
| 6 | RI_Count | | 19 | Founder_Strain_Only |
| 7 | Founder_Fraction | | 20 | Founder_Strain_Both |
| 8 | Founder_Fraction_Strict | | 21 | Founder_Strain_Only_Fraction |
| 9 | RI_Fraction | | 22 | Founder_Strain_Both_Fraction |
| 10 | Presence | | 23 | Founder_Strain_Only_Strict |
| 11 | Presence_Strict | | 24 | Founder_Strain_Both_Strict |
| 12 | Total_Unique_Genotypes | | 25 | Founder_Strain_Only_Fraction_Strict |
| 13 | Founder_Only | | 26 | Founder_Strain_Both_Fraction_Strict |

`Founder_Strain_Only` is a count of how many founder strains carry the
founder-only allele, not an identity. Recovering which founder carries it
requires the per-chromosome split genotype files, which have per-sample columns.

Drop the `_strict` variants:

```bash
cd "$WORKDIR"
cut -f1-4,6-7,9-10,12-22 Processed_variant_genotypes.txt \
  > Processed_variant_genotypes_simplified.txt
```

## 4. Allele presence/absence across assemblies

```bash
cd "$WORKDIR"

eval $( spack load --sh python@3.7.3 )

python "$UPSET_PY" \
  --infile variant_genotypes.txt \
  --outfile variant_genotypes_presence_absence.txt
```

### Collapse redundant assemblies of the same strain

The graph carries three C57BL/6 assemblies (Keane T2T, Yu T2T, GRCm39) and two
CAST/EiJ assemblies. Left separate, those strains would be over-weighted in
allele-sharing counts.

```bash
cd "$WORKDIR"

eval $( spack load --sh python@3.8.12/wcs7jsf )   # python 3.8.12 (build hash wcs7jsf)

python3 "$MERGE_PY" \
  variant_genotypes_presence_absence.txt \
  variant_genotypes_presence_absence.merged_founders.txt
```

Count the distinct presence/absence patterns:

```bash
cd "$WORKDIR"

awk '{for(i=4;i<=NF;i++) printf $i"\t"; print ""}' \
  variant_genotypes_presence_absence.merged_founders.txt \
| sort -r > variant_genotypes_presence_absence_sorted.txt

uniq -c variant_genotypes_presence_absence_sorted.txt \
  > variant_genotypes_presence_absence_counts.txt
```

## 5. Population structure by MDS

```bash
cd "$WORKDIR"

eval $( spack load --sh vcftools )
eval $( spack load --sh plink )

vcftools --vcf founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.splitdiplotype.vcf \
  --plink --out all_crosses

plink --file all_crosses --genome --out all_crosses --noweb

plink --file all_crosses --read-genome all_crosses.genome \
  --cluster --mds-plot 7 --out all_crosses_mds --noweb
```

The MDS coordinates are plotted in `Visualize_PCA_v1_Founder_40_New_RI.Rmd`;
identity-by-state is computed in
`Analyze_Genotype_Matrices_deconstructed_graph_40_NewRI.Rmd`.
