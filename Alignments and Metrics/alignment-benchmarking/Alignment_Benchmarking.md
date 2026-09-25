# Parse alignment statistics into a combined table

Parses per-sample `samtools stats` and `vg stats` output across three references
into a single table for `Alignment_Metrics_Comparison.Rmd`.

> The parsing step reads the `samtools stats` and `vg stats` output files and
> writes the table described below. The output shape, column order and
> aggregation rules are specified here.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `GRAPH_STATS` | `vg stats` output, Founder Pangenome, per sample |
| `GRCM38_STATS` | `samtools stats` output, GRCm38, per lane |
| `T2T_STATS` | `samtools stats` output, Yu-T2T, per lane |

```bash
WORKDIR=/path/to/Alignment_Benchmarking
GRAPH_STATS="$WORKDIR/graph"
GRCM38_STATS="$WORKDIR/GRCm38"
T2T_STATS="$WORKDIR/Yu-T2T"
```

All three were produced upstream by a co-author.

## Input shapes

| Source | Granularity | Count | Naming |
|---|---|---|---|
| `vg stats` (graph) | per sample | 40 | `Founders.CC<NNN>.stats.txt` |
| `samtools stats` (GRCm38) | per lane | 255 | `GRCm38-ref.QCd-<GES>-<CC>-<tissue>_<barcode>_<flowcell>_<lane>_001-query.stats.txt` |
| `samtools stats` (Yu-T2T) | per lane | 255 | `Yu-T2T-ref.QCd-…` as above |

`vg stats` is fixed-format, one metric per line, colon-delimited, with summary
statistics (mean/median/stdev/max) on the alignment-score and mapping-quality
lines. `samtools stats` summary numbers are the `SN` lines
(`grep ^SN | cut -f2-`).

The linear references are per-lane and must be aggregated to per-sample
before they can be compared against the per-sample graph statistics.

## Specification of the parsing step

Output is one row per sample × reference, 120 rows, with 42 columns in a fixed
order.

Aggregation rules for the per-lane samtools inputs:

- count fields are summed across lanes
- rate fields are recomputed from the aggregated counts, not averaged
- insert size and average quality are weighted by reads per lane
- `n_lanes` is carried as a column

Sample ID is extracted with the regex `CC\d+`. A positional split on the
filename fails for Yu-T2T, because that reference name itself contains a hyphen.

### Column groups

| Group | Columns |
|---|---|
| Identifiers | `sample_id`, `reference`, `n_lanes` |
| Shared | `total_reads`, `reads_mapped`, `pct_mapped`, `reads_properly_paired`, `pct_properly_paired` |
| vg only | `total_primary`, `total_secondary`, `total_perfect`, `pct_perfect`, `total_gapless`, `pct_gapless`, `aln_score_{mean,median,stdev}`, `mapq_{mean,median,stdev}`, `{insertions,deletions,substitutions,softclips}_{bp,events}` |
| samtools only | `reads_mapped_and_paired`, `reads_unmapped`, `reads_duplicated`, `reads_MQ0`, `supplementary_alignments`, `total_length`, `bases_mapped`, `bases_mapped_cigar`, `mismatches`, `error_rate`, `average_length`, `average_quality`, `insert_size_average`, `insert_size_sd` |

Metrics that exist in only one space are `NA` in the other;
`Alignment_Metrics_Comparison.Rmd` relies on this.

## Run

```bash
cd "$WORKDIR"
python3 parse_alignment_stats.py
```

## Expected result

`alignment_stats_merged.tsv`, which should satisfy:

| Check | Expectation |
|---|---|
| rows per reference | graph 40, GRCm38 40, Yu-T2T 40 |
| sample coverage | all 40 samples present for each reference |
| NA pattern, graph rows | `reads_MQ0`, `insert_size_average`, `error_rate` are NA |
| NA pattern, linear rows | `total_primary`, `total_perfect` are NA |
