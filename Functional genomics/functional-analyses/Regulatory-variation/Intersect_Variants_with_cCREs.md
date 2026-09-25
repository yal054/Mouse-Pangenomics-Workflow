# Intersect graph variants with cCREs

Intersects the variants deconstructed from the CC pangenome with the ENCODE
candidate cis-regulatory element annotation, quantifying how much variation each
regulatory element carries.

Produces the input to `Intersect_Variants_with_cCREs.Rmd` and
`run_HOMER_on_All_variable_cCREs.md`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `VCF` | normalized deconstructed VCF in mm10 coordinates |
| `CCRE_BED` | ENCODE mm10 cCRE annotation |
| `CLASSIFY_PY` | `Assign_Variant_Classes_Per_Bubble.py` |

```bash
WORKDIR=/path/to/Intersect_Variants_with_cCREs
VCF=/path/to/founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.gz
CCRE_BED=/path/to/mm10-cCREs.All.bed
CLASSIFY_PY="../../../Variant analysis/variant-analyses/per-bubble-variant-classes/Assign_Variant_Classes_Per_Bubble.py"
```

## Outputs

`founder.plus_allCC.deconstruct.mm10.intersect.mm10-cCREs.All.bed`, one row per
variant × cCRE overlap, carrying the variant class and the cCRE class.

## 1. Classify variants per bubble

Same classification used for the per-bubble variant content.

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# python 3.8.12
eval $( spack load --sh /pudl6n3 )

python "$CLASSIFY_PY" "$VCF" \
  -o founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.tsv
```

## 2. Convert the classified variants to BED

Interval is the reference allele span: start is `POS - 1` (BED is 0-based),
end is start plus the reference length. Column 12 of the classification table
carries the variant class.

```bash
cd "$WORKDIR"

awk 'BEGIN{FS=OFS="\t"} NR>1 {print $1, $2-1, $2-1+$4, $3, $12}' \
  founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.tsv \
  > founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.bed
```

## 3. Intersect with the cCRE annotation

`-wo` keeps both records plus the overlap length, so each row carries the
variant, the element it falls in, and how much of it overlaps.

```bash
cd "$WORKDIR"

ln -sf "$CCRE_BED" ./mm10-cCREs.All.bed

eval $( spack load --sh bedtools2@2.30.0/f3mnrck )   # bedtools2 2.30.0 (build hash f3mnrck)

bedtools intersect \
  -a founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.bed \
  -b mm10-cCREs.All.bed \
  -wo \
  > founder.plus_allCC.deconstruct.mm10.intersect.mm10-cCREs.All.bed
```

## 4. Check the result

```bash
cd "$WORKDIR"
OUT=founder.plus_allCC.deconstruct.mm10.intersect.mm10-cCREs.All.bed

# variants per cCRE class
cut -f11 "$OUT" | sort | uniq -c

# number of distinct cCREs carrying at least one variant
cut -f10 "$OUT" | sort -u | wc -l

# most heavily variant-laden elements
cut -f10 "$OUT" | sort | uniq -c | sort -g | tail
```
