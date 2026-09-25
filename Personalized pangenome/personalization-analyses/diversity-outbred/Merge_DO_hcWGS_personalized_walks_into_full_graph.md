# Merge DO high-coverage traversals into the founder graph

Extracts the recombinant-only traversals from each high-coverage DO
personalization result and merges them into a single GBWT.

High-coverage arm (10 samples, 30–60×); the output feeds
`Merge_DO_combined_into_full_graph.md`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `SAMP_ROOT` | personalization results, one `<sample>/sampled.gbz` per sample |
| `FOUNDER_GBWT` | founder GBWT, extracted once in the CC RI merge |
| `REFS_TO_DROP` | reference samples to remove from each GBWT |
| `GBWT_BATCH` | `run_make_and_rename_recombinant_only_gbwt.sh` |
| `CHUNK_BATCH` | `run_merge_gbwt_chunk.sh` |
| `VG` | path to the `vg` binary |

```bash
WORKDIR=/path/to/hcWGS/Merge_personalized_walks_into_full_graph
SAMP_ROOT=/path/to/hcWGS/Personalization_results/full
FOUNDER_GBWT=/path/to/RI_Personalization/.../02_merge/founder.gbwt
REFS_TO_DROP="C57BL_6_T2T_Yu,GRCm39,mm10"
GBWT_BATCH=../run_make_and_rename_recombinant_only_gbwt.sh
CHUNK_BATCH=../run_merge_gbwt_chunk.sh
VG=/path/to/vg
```

## Scale

| | |
|---|---|
| Samples | 10 |
| Input `sampled.gbz` | 3.3–3.4 G each |
| Per-sample GBWT | ~1.9 G each |
| Chunk size | 5 samples → 2 chunks |
| Chunk GBWT | ~2.4 G each |

## Outputs

`02_merge/All_chunk_merged.gbwt`, all 10 samples' recombinant traversals in one
index.

## 1. Set up

```bash
mkdir -p "$WORKDIR"/{00_lists,01_per_sample_gbwt,02_merge}
cd "$WORKDIR"

ls -1 "$SAMP_ROOT"/SRR*_trimmed/sampled.gbz > 00_lists/sampled_gbz.list
wc -l 00_lists/sampled_gbz.list        # expect 10
```

## 2. Extract a recombinant-only GBWT per sample

`run_make_and_rename_recombinant_only_gbwt.sh` converts GBZ to GFA, renames the
`recombination` paths to the sample name, builds a GBWT, and drops the reference
samples. It reads one line per sample from
`params.make_and_rename_recombinant_only_gbwt.tsv`, tab-separated:
`GBZ  SAMPLE  OUTD  REFS_TO_DROP`
`GBZ` is `$SAMP_ROOT/SRR*_trimmed/sampled.gbz`, `SAMPLE` is that directory name,
`OUTD` is `$WORKDIR/01_per_sample_gbwt` and `REFS_TO_DROP` is the comma-separated
list above. 10 lines.

```bash
cd "$WORKDIR"

# Resources used: 96 GB, 8 CPUs per task; all 10 run concurrently
sbatch --array=1-10%10 "$GBWT_BATCH" \
  params.make_and_rename_recombinant_only_gbwt.tsv
```

Confirm 10 GBWTs landed in `01_per_sample_gbwt/`.

> Slurm logs land in the directory the job was submitted from, not `WORKDIR`.

## 3. Reuse the founder GBWT

The founder GBWT was extracted once from the same founder graph during the CC RI
merge and is reused here rather than rebuilt.

```bash
cd "$WORKDIR/02_merge"
ln -s "$FOUNDER_GBWT" founder.gbwt
```

## 4. Merge in chunks

Merging all samples in one pass is memory-prohibitive; the list is split into
chunks, each merged separately, then the chunks merged together.

`params.recombinant_only_gbwts.list` holds one per-sample GBWT path per line
(`01_per_sample_gbwt/SRR*.gbwt`, 10 lines). It is split into chunks of 5 lines,
`02_merge/params.recombinant_only_gbwts.list.chunk_000` onward (2 chunks).

`run_merge_gbwt_chunk.sh` reads one chunk-list path per line from
`params.merge_chunks.tsv` (`CHUNK_LIST`) and writes `chunk_<chunk list name>.gbwt`. 2 lines.

```bash
cd "$WORKDIR/02_merge"

# Resources used: 64 GB, 8 CPUs per task
sbatch --array=1-2%2 "$CHUNK_BATCH" params.merge_chunks.tsv
```

> Chunk GBWTs also land in the submit directory; move them into `02_merge`
> before the next step.

## 5. Merge the chunks into one GBWT

`params.merge_all_chunks.list` holds one chunk GBWT path per line
(`chunk_*.gbwt` in `02_merge`, 2 lines).

```bash
cd "$WORKDIR/02_merge"

CHUNKS=$(tr '\n' ' ' < params.merge_all_chunks.list)

# Resources used: 64 GB, 16 CPUs. ~26 min for 2 x 2.4 G input.
sbatch --mem=64000 --cpus-per-task=16 -J gbwt_merge_all \
  --output=slurm-merge_all_chunks_%j.out \
  --wrap="cd $WORKDIR/02_merge && \
          $VG gbwt --num-threads 16 -m ${CHUNKS} -o All_chunk_merged.gbwt"
```

Continue in `Merge_DO_combined_into_full_graph.md`, which merges this with the
low-coverage arm and the founder GBWT.
