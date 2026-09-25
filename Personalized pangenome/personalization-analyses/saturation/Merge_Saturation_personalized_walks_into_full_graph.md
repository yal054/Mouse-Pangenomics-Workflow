# Merge the downsampled RI traversals into the full graph

Merges the personalized traversals from all downsampled RI libraries into the
founder graph and deconstructs the result to a VCF, so concordance can be scored
at each coverage level.

Follows `Personalize_downsampled_RI_WGS.md`. Its output feeds
`Visualize_Concordance_Results.Rmd`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `SAMP_ROOT` | personalization results, one `<sample>/sampled.gbz` per run |
| `FULL_GBZ` | founder pangenome graph, GBZ |
| `REFS_TO_DROP` | reference samples to remove from each GBWT |
| `GBWT_BATCH` | `run_make_and_rename_recombinant_only_gbwt.sh` |
| `VG` | path to the `vg` binary |

```bash
WORKDIR=/path/to/Saturation_analysis/Merge_personalized_walks_into_full_graph
SAMP_ROOT=/path/to/Saturation_analysis/Personalization_results/full
FULL_GBZ=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.gbz
REFS_TO_DROP="C57BL_6_T2T_Yu,GRCm39,mm10"
GBWT_BATCH=../run_make_and_rename_recombinant_only_gbwt.sh
VG=/path/to/vg
```

## Scale

120 personalization runs: 40 RI lines × 3 downsample fractions (0.25, 0.125,
0.0625).

> Sample names carry the downsample fraction, so all 120 traversals coexist in
> one GBWT without collision and no per-fraction partitioning is needed.

## Outputs

`02_merge/founder.plus_allCC.deconstruct.mm10.raw.vcf.gz`, the deconstructed
VCF with nested snarls decomposed.

## 1. Set up and list the inputs

```bash
mkdir -p "$WORKDIR"/{00_lists,01_per_sample_gbwt,02_merge}
cd "$WORKDIR"

ls -1 "$SAMP_ROOT"/CC*/sampled.gbz > 00_lists/sampled_gbz.list
wc -l 00_lists/sampled_gbz.list        # expect 120
```

## 2. Extract the founder GBWT

```bash
cd "$WORKDIR/02_merge"

# Resources used: 16 threads
"$VG" gbwt --num-threads 16 -o founder.gbwt -Z "$FULL_GBZ"
```

## 3. Extract a recombinant-only GBWT per run

`run_make_and_rename_recombinant_only_gbwt.sh` reads one line per run from
`params.make_and_rename_recombinant_only_gbwt.tsv`, tab-separated:
`GBZ  SAMPLE  OUTD  REFS_TO_DROP`
`GBZ` is `$SAMP_ROOT/<sample>/sampled.gbz`, `SAMPLE` is the name of its parent
directory, `OUTD` is `$WORKDIR/01_per_sample_gbwt` and `REFS_TO_DROP` is the
comma-separated `$REFS_TO_DROP`. 120 lines.

```bash
cd "$WORKDIR"

# Resources used: 96 GB, 8 CPUs per task; 10 concurrent
sbatch --array=1-120%10 "$GBWT_BATCH" \
  params.make_and_rename_recombinant_only_gbwt.tsv
```

## 4. Merge all traversals, then add the founders

`params.recombinant_only_gbwts.list` (in `02_merge`): one per-sample GBWT path
(`../01_per_sample_gbwt/CC*.gbwt`) per line, 120 lines.

```bash
cd "$WORKDIR/02_merge"

"$VG" gbwt --num-threads 16 \
  -m $(tr '\n' ' ' < params.recombinant_only_gbwts.list) \
  -o All_chunk_merged.gbwt

"$VG" gbwt --num-threads 20 \
  -m All_chunk_merged.gbwt founder.gbwt \
  -o founder.plus_allCC.gbwt
```

> For 120 inputs this is memory-heavy. If it does not fit, split the list with
> `split -l <n>`, merge each part with `run_merge_gbwt_chunk.sh`, then merge the
> parts, the approach used in the DO arms. Any split is fine, because the
> sample names are already unique.

## 5. Build the combined GBZ

```bash
cd "$WORKDIR/02_merge"

"$VG" gbwt --num-threads 20 \
  -x "$FULL_GBZ" founder.plus_allCC.gbwt \
  --gbz-format -g founder.plus_allCC.gbz
```

## 6. Deconstruct to VCF

`-a` decomposes nested snarls and `-C` keeps the nesting information; both are
required for the downstream vcfbub normalization.

```bash
cd "$WORKDIR/02_merge"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)

"$VG" deconstruct \
  founder.plus_allCC.gbz \
  -P mm10 \
  -C \
  -a \
  -t 20 \
| bgzip --threads 20 > founder.plus_allCC.deconstruct.mm10.raw.vcf.gz
```

The per-sample GBWTs, the merged intermediate and the founder GBWT are no longer
needed once the GBZ exists.
