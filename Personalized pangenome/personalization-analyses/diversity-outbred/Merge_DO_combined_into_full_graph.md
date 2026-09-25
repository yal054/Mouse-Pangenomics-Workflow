# Merge all DO traversals with the founder GBWT

Combines the low- and high-coverage DO recombinant walks with the founder GBWT
into a single index, for the paired-coverage comparison.

Continues from the two per-arm merges:

- `Merge_DO_lcWGS_personalized_walks_into_full_graph.md`: 48 lcWGS samples
- `Merge_DO_hcWGS_personalized_walks_into_full_graph.md`: 10 hcWGS samples

58 samples across both coverage tiers.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `FOUNDER_GBWT` | founder GBWT, from the CC RI merge |
| `LCWGS_GBWT` | merged lcWGS GBWT (48 samples) |
| `HCWGS_GBWT` | merged hcWGS GBWT (10 samples) |
| `FULL_GBZ` | founder pangenome graph, GBZ |
| `VG` | path to the `vg` binary |

```bash
WORKDIR=/path/to/Merge_DO_combined_into_full_graph
FOUNDER_GBWT=/path/to/founder.gbwt
LCWGS_GBWT=/path/to/lcWGS/02_merge/All_chunk_merged.gbwt
HCWGS_GBWT=/path/to/hcWGS/02_merge/All_chunk_merged.gbwt
FULL_GBZ=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.gbz
VG=/path/to/vg
```

The founder graph was produced upstream.

## Merge order matters

`vg gbwt -m` inserts each index into the first. Pass the smallest index
first so the larger ones are inserted into it; passing a large index into a
substantially smaller one triggers a vg warning and is slower.

| Order | Index | Approx. size |
|---|---|---|
| 1 | founder GBWT | 2.7 G |
| 2 | lcWGS GBWT (48 samples) | 2.6 G |
| 3 | hcWGS GBWT (10 samples) | 2.5 G |

## 1. Verify the inputs are present

```bash
ls -lh "$FOUNDER_GBWT" "$LCWGS_GBWT" "$HCWGS_GBWT"
```

Roughly 7.8 G in total across the three.

## 2. Merge into a combined GBWT

```bash
mkdir -p "$WORKDIR/02_merge"
cd "$WORKDIR/02_merge"

# Resources used: 128 GB, 20 CPUs.
# The CC run used 72 GB for two inputs totalling ~5.3 G; scaled up here for
# three inputs totalling ~7.8 G.
sbatch --mem=128000 --cpus-per-task=20 -J gbwt_merge_allDO \
  --output=slurm-merge_allDO_%j.out \
  --wrap="cd $WORKDIR/02_merge && \
          $VG gbwt --num-threads 20 \
            -m $FOUNDER_GBWT $LCWGS_GBWT $HCWGS_GBWT \
            -o founder.plus_allDO.gbwt"
```

## Downstream

Building the combined GBZ from this GBWT and deconstructing it to a VCF is in
`Merge_lc_and_hc_personalization.md`.
