# Prepare the CC Pangenome for Ixchel surjection

Converts the CC Pangenome into the per-chromosome rGFA and precomputed
conversion files that Ixchel needs to map graph coordinates onto a linear
reference.

Produces `Annotations.converted.db`, the conversion database used by
`Surject_methylation_calls_v2_FullGraph_mq10.md`, and the graph-space
methylation view.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `CC_GBZ` | CC Pangenome graph, GBZ |
| `CHUNK_DIR` | per-chromosome `.vg` chunks (see note below) |
| `SPLIT_ANNOTATIONS` | per-chromosome annotation files to convert |
| `REFERENCE_NAME` | reference path name in the graph |
| `VG` | path to the `vg` binary |
| `IXCHEL_SCRIPTS` | Ixchel stepwise-processing scripts |

```bash
WORKDIR=/path/to/Per_Chromosome_Ixchel_Process_CC_graph
CC_GBZ=/path/to/founder.plus_allCC.gbz
CHUNK_DIR=/path/to/chunked_graph
SPLIT_ANNOTATIONS="$WORKDIR/split_annotations"
REFERENCE_NAME=C57BL_6_T2T_Yu
VG=/path/to/vg
IXCHEL_SCRIPTS=/path/to/Ixchel/bash_Scripts_For_Stepwise_Processing
```

> The graph carries three reference paths: `GRCm39`, `C57BL_6_T2T_Yu` and
> `mm10`. Ixchel is given `C57BL_6_T2T_Yu`. Confirm the name by inspecting a
> chunk's GFA header before running.

## 1. Convert GBZ to GFA

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Resources used: 128 GB, 20 CPUs
sbatch --mem=128000 --cpus-per-task=20 --wrap \
  "$VG convert -t 20 -f $CC_GBZ > $WORKDIR/founder.plus_allCC.gfa"
```

## 2. Convert GFA to PG

```bash
cd "$WORKDIR"
# Resources used: ~111 GB, ~3 h 18 min
sbatch "$PG_BATCH" founder.plus_allCC.gfa founder.plus_allCC.pg
```

## 3. Split into per-chromosome chunks

> This step was run separately by a co-author because the chunking needed
> more memory than the rest of the pipeline. It produces 22 `.vg` chunks
> (~76 GB total).

## 4. Convert chunks to GFA and identify chromosomes

Chunk numbering does not correspond to chromosome order, so each chunk's
identity is read from field 4 of its `W` lines.

```bash
cd "$WORKDIR"

# ~46 min for all 22
for i in $(seq 0 21); do
    "$VG" convert -f "chunk_${i}.vg" > "chunk_${i}.gfa"
done

for i in $(seq 0 21); do
  f="chunk_${i}.gfa"
  chr=$(grep "^W" "$f" | awk '{print $4}' | sort -u | tr '\n' ',')
  echo "chunk_${i}: $chr"
done
```

Rename each `chunk_N.gfa` / `chunk_N.vg` to its chromosome using that mapping,
and organize into `gfa/` and `vg/`.

## 5. Convert GFA to rGFA

`run_Batch_convert_GFA_to_rGFA.sh` reads one line per chromosome from `convert_gfa_to_rGFA_parameters.txt`, tab-separated:
`INPUTGFA  REFERENCE  OUTPUTRGFA`
`REFERENCE` is `$REFERENCE_NAME` and `OUTPUTRGFA` replaces the `.gfa` suffix
with `.rgfa`. 22 lines.

```bash
cd "$WORKDIR"

for f in gfa/chr*.gfa; do ln -s "${PWD}/${f}" .; done

sbatch --array=1-22%22 "$RGFA_BATCH" convert_gfa_to_rGFA_parameters.txt
```

## 6. prepareGraphFiles

> Use the `.rgfa` files, not the `.gfa` files. `prepareGraphFiles` locates
> reference segments by their `SN:Z:` tags, which only rGFA carries. With
> `.gfa` input the run completes without error but writes empty
> `RefOnly.Segments.chr*.pkl` files (68 bytes, zero reference lines), and every
> downstream product (PreConvertAnnotations, Annotations.converted, the
> database) is invalid. Correct output is large: ~457 MB for chr1.

`run_Batch_Ixchel_prepareGraphFiles.sh` reads one line per chromosome from `prepareGraphFiles_parameters.txt`, tab-separated:
`RGFA  REFERENCE`
`REFERENCE` is `$REFERENCE_NAME`. 22 lines.

```bash
cd "$WORKDIR"

for f in rgfa/chr*.rgfa; do ln -s "${PWD}/${f}" .; done

sbatch --array=1-22%22 \
  "$IXCHEL_SCRIPTS/run_Batch_Ixchel_prepareGraphFiles.sh" \
  prepareGraphFiles_parameters.txt
```

Check the `RefOnly.Segments.*.pkl` sizes before continuing. Near-empty files
mean the `.gfa`/`.rgfa` mistake above.

## 7. Build precomputed conversion files

The Ixchel conversion step reads one line per annotation file in `$SPLIT_ANNOTATIONS` from `conversion_parameters.txt`, tab-separated:
`ANNOTATION  REFONLY_SEGMENTS_PKL  QUERYONLY_SEGMENTS_PKL  FILTEREDLINKS_PKL`
Each annotation file's chromosome is parsed from its name and used to select
the matching `RefOnly.Segments.<chr>.pkl`, `QueryOnly.Segments.<chr>.pkl` and
`FilteredLinks.Links.<chr>.pkl` from step 6.

Submit as an array over the annotation files, then concatenate the converted
output and build the SQLite database.

> Start the database build only after the concatenation completes. Started
> earlier, it fails with `FileNotFoundError` and leaves a 12 KB stub database
> that must be deleted before rebuilding.

The resulting `Annotations.converted.db` is the conversion database consumed by
the surjection protocol.
