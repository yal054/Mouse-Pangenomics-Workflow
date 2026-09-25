# QC of the DeepVariant callsets

Collects per-variant quality metrics from the DeepVariant callsets, and runs
`bcftools stats` across them.

Feeds `Visualize_QC_metrics.Rmd` and `Visualize_bcftools_stats_unfiltered.Rmd`.

## Filtering

The benchmark in `GQ20_DV-vcfeval.md` runs on the unfiltered callsets. These
thresholds were evaluated and not applied:

| Criterion | Threshold considered |
|---|---|
| Filter status | keep `PASS` only |
| Depth | between 0.5× and 1.5× the per-sample median DP |
| Genotype quality | GQ ≥ 20 |
| Variant allele fraction | VAF ≥ 0.2 |

The metric distributions showed a clear separation in variant quality by
reference, and further filtering was judged not to change the comparison.

The GQ 20 threshold in `GQ20_DV-vcfeval.md` is applied at the evaluation step,
not here.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `DV_DIR` | DeepVariant output, one directory per sample × method |
| `QC_PY` | `collect_deepvariant_qc_metrics.py` |
| `STATS_BATCH` | `run_Batch_bcftools_stats.sh` |

```bash
WORKDIR=/path/to/Variant_Calling_Benchmark
DV_DIR="$WORKDIR/deepvariant"
QC_PY=collect_deepvariant_qc_metrics.py
STATS_BATCH=run_Batch_bcftools_stats.sh
```

## Outputs

`deepvariant_qc_metrics/deepvariant_qc*.tsv`, per-variant metrics, and one
`.stats` file per callset.

## 1. Flatten the DeepVariant output layout

As delivered, each callset sits in its own `<sample>-<method>/` directory with
the same filename inside. Flatten to `<method>_<sample>.vcf.gz` so callsets are
distinguishable in one directory.

```bash
cd "$WORKDIR"

for d in "$DV_DIR"/CC*-*; do
    sample=$(basename "$d" | cut -d'-' -f1)
    method=$(basename "$d" | sed "s/^${sample}-//")

    mv "$d/${sample}.vcf.gz"     "$DV_DIR/${method}_${sample}.vcf.gz"
    mv "$d/${sample}.vcf.gz.tbi" "$DV_DIR/${method}_${sample}.vcf.gz.tbi"
done

find . -type d -empty -delete
```

## 2. Collect per-variant QC metrics

Done in Python because the callsets are too large to read into R efficiently.

```bash
cd "$WORKDIR"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh python@3.8.12/pudl6n3 )   # python 3.8.12 (build hash pudl6n3)

python3 "$QC_PY" \
  --vcf_dir "$DV_DIR" \
  --out_prefix deepvariant_qc

mkdir -p deepvariant_qc_metrics
mv deepvariant_qc*.tsv deepvariant_qc_metrics/
```

The metric distributions are examined in `Visualize_QC_metrics.Rmd`.

## 3. Run bcftools stats across the unfiltered callsets

`run_Batch_bcftools_stats.sh` reads one line per callset from
`bcftools_stats_params.txt`, tab-separated:
`INPUTVCF  OUTPUT`
`INPUTVCF` is a `*.vcf.gz` under `$DV_DIR`, and `OUTPUT` is its basename with
`.vcf.gz` replaced by `.stats`. 80 lines: 40 samples x 2 methods.

```bash
cd "$WORKDIR"

sbatch --array=1-80%10 "$STATS_BATCH" bcftools_stats_params.txt
```

Results are compared across samples in
`Visualize_bcftools_stats_unfiltered.Rmd`.
