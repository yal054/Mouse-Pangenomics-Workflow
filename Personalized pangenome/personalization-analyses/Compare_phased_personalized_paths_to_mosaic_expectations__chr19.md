# Merge phased chr19 traversals with the founder panel

Combines the Gnomix-phased CC RI traversals for chromosome 19 with the founder
reference panel into a single VCF, for visualization against the expected
haplotype mosaic.

Produces the input to
`Compare_phased_personalized_paths_to_mosaic_expectations__chr19.Rmd`.
Concordance is not recalculated here: phasing moves alleles between haplotypes
but does not change the set of alleles called at a site, so the concordance in
`Compare_personalized_paths_to_mosaic_expectations.md` still holds.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `REF_PANEL_VCF` | founder reference panel for chr19, from `phasing/Gnomix_CC_RI_Phasing.md` |
| `PHASED_VCF` | Gnomix-phased query output for chr19 |

```bash
WORKDIR=/path/to/Compare_phased_personalized_paths_to_mosaic_expectations__chr19
REF_PANEL_VCF=/path/to/Gnomix_CC_Phasing/RefPanel/ref.chr19.vcf.gz
PHASED_VCF=/path/to/Gnomix_CC_Phasing/gnomix_output_chr19/query_file_phased.vcf
```

## Outputs

`RI_Phased_chr19.vcf.gz`, founders and phased RI traversals in one VCF.

## 1. Stage, compress and index both VCFs

Both must be bgzip-compressed and tabix-indexed for `bcftools merge`. The
reference panel is re-compressed because a plain gzip stream is not bgzip and
cannot be indexed.

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

cp "$REF_PANEL_VCF" ./ref.chr19.vcf.gz
cp "$PHASED_VCF"    ./query_file_phased.vcf

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools/wvf7267 )   # samtools, version not recorded (build hash wvf7267)

gzip -d ref.chr19.vcf.gz
bgzip ref.chr19.vcf
bgzip query_file_phased.vcf

tabix -p vcf ref.chr19.vcf.gz
tabix -p vcf query_file_phased.vcf.gz
```

## 2. Merge

```bash
cd "$WORKDIR"

eval $( spack load --sh bcftools/7p7na33 )   # bcftools, version not recorded (build hash 7p7na33)

bcftools merge -o RI_Phased_chr19.vcf.gz \
  ref.chr19.vcf.gz \
  query_file_phased.vcf.gz
```
