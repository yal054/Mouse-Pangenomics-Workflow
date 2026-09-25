# Score personalized traversals against the expected mosaic

Compares the alleles selected by pangenome personalization against those
predicted by the published CC haplotype mosaics, at every variant site, for all
40 RI lines.

Also produces the per-site non-concordance data that
defines the exclusion regions.

## The truth set

The published mosaics (Srivastava et al. 2017) assign each genomic interval of
each RI line a founder diplotype. Where an interval is assigned, the alleles
carried by those founders over that interval are what personalization should
have selected. Sites outside any assigned interval cannot be scored.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `VCF_RAW` | top-level deconstructed VCF, prefix-stripped |
| `VCF_NORM` | vcfbub-normalized, sorted VCF |
| `SCORE_BATCH` | `run_Batch_score_mosaic_concordance.sh` |
| `NONCONC_BATCH` | `run_Batch_find_nonconcordant_sites.sh` |
| `FAI` | mm10 `.fai`, for binning |

```bash
WORKDIR=/path/to/CC_genotype_comparison_to_muga_array
VCF_RAW=/path/to/founder.plus_allCC.deconstruct.mm10.vcf
VCF_NORM=/path/to/founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.gz
SCORE_BATCH=run_Batch_score_mosaic_concordance.sh
NONCONC_BATCH="../../Variant analysis/variant-analyses/ri-population-genetics/exclusions/run_Batch_find_nonconcordant_sites.sh"
FAI=/path/to/mm10.fa.fai
```

## 1. Retrieve the mosaic haplotype files

Published at `https://csbio.unc.edu/CCstatus/CCGenomes/CCGenomes/`.

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

curl -sL "https://csbio.unc.edu/CCstatus/index.py?run=CCGenomes.test" \
  | grep -Eo 'href="[^"]+\.hap"' \
  | sed -E 's/^href="//; s/"$//' \
  | awk '{
      if ($0 ~ /^https?:\/\//) print $0;
      else print "https://csbio.unc.edu/CCstatus/CCGenomes/CCGenomes/" $0
    }' \
  | sort -u > hap_urls.txt

mkdir -p mosaic_haplotypes
cd mosaic_haplotypes
wget -i ../hap_urls.txt
```

### Keep only the NYGC call set

The site serves several variants per line. Only the `CC*_NYGC.hap` files are
used. The `_MRCAs` files are ancestral reconstructions and the `.1` files are
duplicates.

```bash
cd "$WORKDIR/mosaic_haplotypes"
rm -f CC*_NYGC.hap.1 CC*_MRCAs.hap CC*_UNC.hap.1
```

Rename to `<sample>.hap` so downstream steps can address them by sample:

```bash
cd "$WORKDIR/mosaic_haplotypes"

paste \
  <(find . -type f | cut -d/ -f2) \
  <(find . -type f | cut -d/ -f2 | cut -d- -f1 | cut -d_ -f1) \
  > file_to_sample_mapping.tsv

while IFS=$'\t' read -r file sample; do
  mv "$file" "${sample}.hap"
done < file_to_sample_mapping.tsv
```

## 2. Strip the path prefix from the VCF contig names

`vg deconstruct` emits PanSN names (`mm10#0#chr1`); the mosaic files use plain
contig names.

```bash
cd "$WORKDIR"

ln -s "$VCF_RAW" .
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh bcftools/6unbpgv )   # bcftools, version not recorded (build hash 6unbpgv)

VCF=$(basename "$VCF_RAW")

bcftools view -h "$VCF" \
  | grep '^##contig=<ID=mm10#0#' \
  | sed -E 's/^##contig=<ID=([^,>]+).*/\1/' \
  | awk 'BEGIN{FS=OFS="\t"} {old=$1; new=$1; sub(/^mm10#0#/,"",new); print old, new}' \
  > rename_chrs.tsv

bcftools annotate --rename-chrs rename_chrs.tsv \
  -Ov -o founder.plus_allCC.deconstruct.mm10.noprefix.vcf "$VCF"
```

## 3. Score concordance for all 40 lines

More mosaic files exist than lines personalized, so the sample list is taken
from the VCF header (the `CC0*` sample columns) rather than the mosaic directory.

`run_Batch_score_mosaic_concordance.sh` reads one line per sample from
`concordance_parameters.tsv`, tab-separated:
`VCF  SAMPLE  HAPL  OUT`
`VCF` is `founder.plus_allCC.deconstruct.mm10.noprefix.vcf` on every line,
`HAPL` is `mosaic_haplotypes/<sample>.hap` and `OUT` is
`Mosaic_concordance_results/<sample>_mosaic_concordance.tsv`. 40 lines.

```bash
cd "$WORKDIR"

mkdir -p Mosaic_concordance_results

sbatch --array=1-40%40 "$SCORE_BATCH" concordance_parameters.tsv
```

Visualized in `Visualize_Concordance_Results_norm.Rmd`.

## 4. Positional non-concordance, on the normalized VCF

The scoring above ran on the raw deconstruction, which is valid because the
comparison is internal to the graph. It is repeated on the normalized VCF
for the positional analysis, since that is the callset the downstream
population genetics uses.

`run_Batch_find_nonconcordant_sites.sh` reads one line per sample from
`nonconcordance_positions_parameters_norm.tsv`, tab-separated:
`VCF  SAMPLE  HAPL  OUT`
`VCF` is the normalized VCF (basename of `$VCF_NORM`) on every line, samples are
the `CC0*` columns of its header, `HAPL` is `mosaic_haplotypes/<sample>.hap` and
`OUT` is `Mosaic_positional_concordance_norm/<sample>.nonconcordant.bed`. 40 lines.

```bash
cd "$WORKDIR"

ln -s "$VCF_NORM" .
ln -s "${VCF_NORM}.tbi" .

mkdir -p Mosaic_positional_concordance_norm

sbatch --array=1-40%40 "$NONCONC_BATCH" nonconcordance_positions_parameters_norm.tsv
```

## 5. Aggregate non-concordance

Bin-level enrichment against a shuffled null, and a per-site summary across
animals. These identify the regions where personalization is unreliable; see
`../../Variant analysis/variant-analyses/ri-population-genetics/exclusions/`.

```bash
cd "$WORKDIR"

python3 "../../Variant analysis/variant-analyses/ri-population-genetics/exclusions/enrich_nonconcordance_bins.py" \
  --window-size 1000000 \
  --n-shuffles 1000 \
  --indir Mosaic_positional_concordance_norm \
  --fai "$FAI" \
  --out nonconcordance_bin_enrichment.bed \
  --outcomes Mismatch,Missing_Both,Missing_Sample,Missing_Founder

python3 "../../Variant analysis/variant-analyses/ri-population-genetics/exclusions/summarize_nonconcordance_sites.py" \
  --indir Mosaic_positional_concordance_norm \
  --out Mosaic_positional_concordance_norm.site_summary.tsv
```

Visualized in `Visualize_nonconcordance_bin_enrichment.Rmd` and
`Visualize_Concordance_Results_Per_Site_Summary.Rmd`.
