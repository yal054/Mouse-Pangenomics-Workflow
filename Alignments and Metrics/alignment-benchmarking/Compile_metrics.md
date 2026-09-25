# Collect per-sample alignment metrics

Gathers the `samtools stats`, `samtools flagstat` and custom-metrics files for
all five alignment conditions into one directory tree, ready for parsing by
`Alignment_Benchmarking.md`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | output directory |
| `SRC_ROOT` | root of the upstream alignment outputs |

```bash
WORKDIR=/path/to/Alignment_Benchmarking
SRC_ROOT=/path/to/MPRC/alignments
```

The alignments and their metrics were produced upstream by a co-author.

## Conditions

Five conditions, each contributing 40 samples.

| Local directory | Source, relative to `SRC_ROOT` | File pattern |
|---|---|---|
| `GRCm38_BWA` | `linear/GRCm38/DV_processing/sample-merge` | `*.merged.*` |
| `mT2T_BWA` | `linear/Yu-T2T/merge-dir/sample-merge` | `*.merged.*` |
| `GRCm38_Giraffe` | `flat-giraffe/mm10/real` | `*.*` |
| `mT2T_Giraffe` | `flat-giraffe/Yu-T2T/real` | `*.*` |
| `Founders` | `graph/Founders/alignments` | `*.*` |

Three metric files per sample in each condition:

| Suffix | Produced by |
|---|---|
| `.stats.txt` | `samtools stats` |
| `.flagstats` | `samtools flagstat` |
| `.custom-metrics.txt` | custom counts: primary/mapped/paired, MAPQ60, gapless, perfect |

> The BWA conditions carry a `.merged.` infix because their per-library
> alignments were merged per sample before metrics were taken; the Giraffe
> conditions do not.

## Collect

```bash
mkdir -p "$WORKDIR/Metrics"
cd "$WORKDIR/Metrics"

# local_dir : source_subdir : filename infix
CONDITIONS="
GRCm38_Giraffe:flat-giraffe/mm10/real:
mT2T_Giraffe:flat-giraffe/Yu-T2T/real:
Founders:graph/Founders/alignments:
GRCm38_BWA:linear/GRCm38/DV_processing/sample-merge:merged.
mT2T_BWA:linear/Yu-T2T/merge-dir/sample-merge:merged.
"

echo "$CONDITIONS" | while IFS=: read -r local src infix; do
    [ -z "$local" ] && continue
    mkdir -p "$local"
    for suffix in custom-metrics.txt flagstats stats.txt; do
        cp "$SRC_ROOT/$src"/*."${infix}${suffix}" "$local/" 2>/dev/null
    done
done
```

## Verify

Each condition should hold 40 samples × 3 files.

```bash
cd "$WORKDIR/Metrics"
for d in */; do
    printf '%-18s %s files\n' "${d%/}" "$(find "$d" -type f | wc -l)"
done
```

`Alignment_Benchmarking.md` validates sample counts per condition and will
report any shortfall.
