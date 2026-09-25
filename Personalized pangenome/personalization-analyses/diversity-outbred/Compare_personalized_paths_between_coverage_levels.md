# Allele sharing between paired DO coverage levels

Measures, for each DO animal sequenced twice, the fraction of variant sites at
which personalization selected the same alleles from its low-coverage and its
high-coverage library, and compares that against nulls built from unrelated
pairs.

Produces the inputs to
`Per_site_concordance_rate.Rmd`.

## Why this design

The DO animals have no published haplotype mosaic, so there is no truth set to
score against as there is for the RI lines. Instead the question becomes
reproducibility: given the same animal sequenced at 1–5× and at 30–60×, does
personalization recover the same traversal?

That number is only interpretable against a baseline, so three null sets of
unrelated pairs are computed alongside it.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `VCF` | combined DO deconstructed VCF, contig prefixes stripped |
| `FAM` | PLINK2 `.fam` from the combined callset, used for sample lists |
| `SHARE_BATCH` | `run_Batch_Calc_pairwise_allele_shared_fraction.sh` |
| `SUMMARY_BATCH` | `run_Batch_calc_pairwise_allele_summary.sh` |
| `BINS_BATCH` | `run_Batch_calc_pairwise_allele_10kb_bins.sh` |

```bash
WORKDIR=/path/to/DO_Personalizaiton
VCF="$WORKDIR/founder.plus_allDO.deconstruct.mm10.noprefix.vcf.gz"
FAM="$WORKDIR/Plink2_Files/all_crosses_autosomes.fam"
SHARE_BATCH=run_Batch_Calc_pairwise_allele_shared_fraction.sh
SUMMARY_BATCH=run_Batch_calc_pairwise_allele_summary.sh
BINS_BATCH=run_Batch_calc_pairwise_allele_10kb_bins.sh
```

## The 10 matched pairs

48 low-coverage libraries and 10 high-coverage; only 10 animals appear in both.

| low coverage | high coverage |
|---|---|
| SRR33438148 | SRR33939704 |
| SRR33438149 | SRR33939705 |
| SRR33438156 | SRR33939696 |
| SRR33438162 | SRR33939697 |
| SRR33438169 | SRR33939698 |
| SRR33438173 | SRR33939699 |
| SRR33438176 | SRR33939700 |
| SRR33438178 | SRR33939701 |
| SRR33438187 | SRR33939702 |
| SRR33438192 | SRR33939703 |

> The accessions do not state which libraries come from the same animal. The
> pairing was recovered from a kinship analysis (PLINK `PI_HAT`) on the combined
> callset, in which the matched pairs separate clearly from all other pairs. At
> low coverage the genotypes are too distorted for the kinship values to be
> interpretable, but they are sufficient to identify which libraries pair.
>
> Sample names carry a `_trimmed` suffix in the VCF.

## 1. Allele sharing for the matched pairs

```bash
cd "$WORKDIR"

cat > true_pairs_lc_hc.txt <<'EOF'
SRR33438148_trimmed	SRR33939704_trimmed
SRR33438149_trimmed	SRR33939705_trimmed
SRR33438156_trimmed	SRR33939696_trimmed
SRR33438162_trimmed	SRR33939697_trimmed
SRR33438169_trimmed	SRR33939698_trimmed
SRR33438173_trimmed	SRR33939699_trimmed
SRR33438176_trimmed	SRR33939700_trimmed
SRR33438178_trimmed	SRR33939701_trimmed
SRR33438187_trimmed	SRR33939702_trimmed
SRR33438192_trimmed	SRR33939703_trimmed
EOF
```

`run_Batch_Calc_pairwise_allele_shared_fraction.sh` reads one line per pair from
`pairwise_allele_sharing_params.txt`, tab-separated:
`VCF  SAMPLE1  SAMPLE2  OUTPUT`
`SAMPLE1` and `SAMPLE2` are the two columns of `true_pairs_lc_hc.txt`, and
`OUTPUT` is `pairwise_allele_shared_fraction_<lc>_vs_<hc>.tsv` with the
`_trimmed` suffix dropped. 10 lines.

```bash
cd "$WORKDIR"
sbatch --array=1-10%10 "$SHARE_BATCH" pairwise_allele_sharing_params.txt
```

## 2. Build the three null sets

```bash
cd "$WORKDIR"
mkdir -p Parameters/null_pairwise_allele_sharing
cd Parameters/null_pairwise_allele_sharing

awk '$2 ~ /^SRR334/ {print $2}' "$FAM" > lc_samples.txt   # 48
awk '$2 ~ /^SRR339/ {print $2}' "$FAM" > hc_samples.txt   # 10
```

**lc:hc null**: every cross-coverage pair except the 10 true ones, which are
excluded so the null does not contain the signal being tested.

```bash
awk 'NR==FNR {hc[++nh]=$1; next}
     { for(i=1;i<=nh;i++) print $1 "\t" hc[i] }' \
  hc_samples.txt lc_samples.txt > all_pairs_lc_hc.txt

grep -F -v -f ../../true_pairs_lc_hc.txt all_pairs_lc_hc.txt \
  > all_pairs_lc_hc_null_candidates.txt      # 480 - 10 = 470
```

**hc:hc and lc:lc nulls**: all unordered within-coverage pairs. These separate
"different animal" from "different coverage".

```bash
awk '{x[NR]=$1} END{for(i=1;i<=NR;i++) for(j=i+1;j<=NR;j++) print x[i] "\t" x[j]}' \
  hc_samples.txt > all_pairs_hc_hc.txt        # C(10,2) = 45

awk '{x[NR]=$1} END{for(i=1;i<=NR;i++) for(j=i+1;j<=NR;j++) print x[i] "\t" x[j]}' \
  lc_samples.txt > all_pairs_lc_lc.txt        # C(48,2) = 1128
```

The lc:hc and lc:lc candidate sets are subsampled to 100 pairs each; hc:hc is
run in full at 45.

## 3. Compute allele sharing for the nulls

Each null set has its own params file,
`null_pairwise_allele_sharing_params_{lc_hc,hc_hc,lc_lc}.txt`, with the same
tab-separated `VCF  SAMPLE1  SAMPLE2  OUTPUT` layout. The pairs come from
`Parameters/null_pairwise_allele_sharing/null_pairs_<set>.txt`, and `OUTPUT` is
`pairwise_allele_shared_fraction_null_<set>_<a>_vs_<b>.tsv` with the `_trimmed`
suffix dropped. 100, 45 and 100 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-100%100 "$SHARE_BATCH" null_pairwise_allele_sharing_params_lc_hc.txt
sbatch --array=1-45%45   "$SHARE_BATCH" null_pairwise_allele_sharing_params_hc_hc.txt
sbatch --array=1-100%100 "$SHARE_BATCH" null_pairwise_allele_sharing_params_lc_lc.txt
```

## 4. Per-pair summary statistics

`run_Batch_calc_pairwise_allele_summary.sh` reads one path per line from
`pairwise_lc_hc_allele_shared_fraction_summary_params.txt`: one per-site sharing
TSV written by `run_Batch_Calc_pairwise_allele_shared_fraction.sh`. It writes `<input>_summary.tsv` next to each.

```bash
cd "$WORKDIR"
sbatch --array=1-100%100 "$SUMMARY_BATCH" pairwise_lc_hc_allele_shared_fraction_summary_params.txt
```

Genome-wide mean sharing across the 10 matched pairs is 89.4% (s.d. 3.1%), with
no apparent dependence on the coverage achieved by either library.

## 5. Bin into 10 kb windows

Site-level sharing is noisy; binning gives the positional view.

`run_Batch_calc_pairwise_allele_10kb_bins.sh` reads one path per line from each
`*_10kb_bin_params.txt`: one per-site sharing TSV from the null set named in the file. It
writes `<input>_10kb_bins.tsv` next to each.

```bash
cd "$WORKDIR"
sbatch --array=1-100%100 "$BINS_BATCH" pairwise_allele_shared_fraction_null_lc_hc_10kb_bin_params.txt
sbatch --array=1-45%45   "$BINS_BATCH" pairwise_allele_shared_fraction_null_hc_hc_10kb_bin_params.txt
```

Binned results are collected under `Per_site_concordance_rate/` and its null
counterparts, and read by `Per_site_concordance_rate.Rmd`.
