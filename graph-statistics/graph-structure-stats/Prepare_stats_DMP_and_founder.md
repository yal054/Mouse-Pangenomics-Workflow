# Assemble graph statistics for the DMP and Founder Pangenome

Collects the `vg stats` and Panacus outputs for the Draft Mouse Pangenome (DMP)
and the Founder Pangenome (FP), and computes the node degree distribution for
each.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | output directory for the collected statistics |
| `DMP_STATS_TGZ` | `vg stats` archive for the DMP |
| `FP_STATS_TGZ` | `vg stats` archive for the Founder Pangenome |
| `DMP_PANACUS_HIST` | Panacus coverage histogram for the DMP |
| `FP_PANACUS_HIST` | Panacus coverage histogram for the Founder Pangenome |
| `DMP_GBZ` | DMP graph, GBZ format |
| `FP_GBZ` | Founder Pangenome graph, GBZ format |
| `VG` | path to the `vg` binary |

```bash
WORKDIR=/path/to/graph_descriptive_statistics
DMP_STATS_TGZ=/path/to/DMP.stats.tgz
FP_STATS_TGZ=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.stats.tgz
DMP_PANACUS_HIST=/path/to/DMP.full.panacus-hist.tsv
FP_PANACUS_HIST=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.panacus-hist.tsv
DMP_GBZ=/path/to/DMP.full.gbz
FP_GBZ=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.gbz
VG=/path/to/vg
```

The statistics archives and Panacus histograms were produced upstream.

## Outputs

`vg_stats/DMP.stats/` and `vg_stats/Founder.stats/`, each containing the
unpacked `vg stats` output plus a degree-distribution table, and `panacus/`
holding the two coverage histograms.

## 1. Unpack the vg stats archives

The archives carry a Cromwell execution tree; flatten it and discard the
workflow scaffolding.

```bash
mkdir -p "$WORKDIR/vg_stats"
cd "$WORKDIR/vg_stats"

for pair in "DMP.stats:$DMP_STATS_TGZ" "Founder.stats:$FP_STATS_TGZ"; do
    name="${pair%%:*}"
    archive="${pair#*:}"
    mkdir -p "$name"
    tar -xzf "$archive" -C "$name"
    find "$name" -type f -exec mv {} "$name"/. \;
    rm -r "$name/cromwell-executions"
done
```

## 2. Collect the Panacus histograms

```bash
mkdir -p "$WORKDIR/panacus"
cp "$DMP_PANACUS_HIST" "$FP_PANACUS_HIST" "$WORKDIR/panacus/"
```

## 3. Compute the node degree distribution

```bash
cd "$WORKDIR/vg_stats"

"$VG" stats "$DMP_GBZ" -v -D > DMP.stats/stats__degree_distribution__DMP.full.txt
"$VG" stats "$FP_GBZ"  -v -D > Founder.stats/stats__degree_distribution__Founder.full.txt
```

Both graphs must be available locally for this step; `vg stats -D` reads the
full graph.
