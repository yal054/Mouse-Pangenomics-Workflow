# Surject graph methylation calls to reference coordinates

Converts methylGrapher's graph-space methylation calls into linear mT2T
coordinates using the precomputed Ixchel conversion database, filters them, and
indexes the result. Uses the full-graph, MapQ > 10 calls.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `GRAPH_METHYL` | `.graph.methyl` files from `Download_methylGrapher_graph_results_v2_FullGraph_mq10.md` |
| `CONVERSION_DB` | `Annotations.converted.db`, from `Per_Chromosome_Ixchel_Process_CC_graph.md` |
| `SORT_BATCH` | `run_Batch_sort_Graph.Methyl_files.sh` |
| `CONVERT_BATCH` | `run_Batch_Ixchel_convertGraphMethylToMethylC.sh` |

```bash
WORKDIR=/path/to/methylGrapher_v2_FullGraph_mq10/Surjection
GRAPH_METHYL=/path/to/methylGrapher_v2_FullGraph_mq10/GraphMethyl
CONVERSION_DB=/path/to/Annotations.converted.db
SORT_BATCH=run_Batch_sort_Graph.Methyl_files.sh
CONVERT_BATCH=run_Batch_Ixchel_convertGraphMethylToMethylC.sh
```

## Outputs

`Filtered_Sorted_methylC/Sorted__<sample>.filtered.cleaned.methylC.gz` plus
tabix indices, 10 call sets on mT2T coordinates.

## 1. Sort the graph methylation calls

Conversion requires sorted input.

`run_Batch_sort_Graph.Methyl_files.sh` reads one line per sample from `sorting_params.txt`, tab-separated:
`UNSORTEDFILE  SORTEDFILE`
`UNSORTEDFILE` is a symlinked `<sample>.graph.methyl` and `SORTEDFILE` is the
same name prefixed with `Sorted__`. 10 lines.

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

for i in "$GRAPH_METHYL"/*.methyl; do ln -s "$i" .; done

sbatch --array=1-10%10 "$SORT_BATCH" sorting_params.txt

rm -f ./*.graph.methyl        # the input symlinks
```

## 2. Convert graph coordinates to reference coordinates

`run_Batch_Ixchel_convertGraphMethylToMethylC.sh` reads one line per sample from `conversion_params.txt`, tab-separated:
`GRAPHMETHYLFILE  PRECOMPUTEDDB  METHYLCOUTPUT`
`GRAPHMETHYLFILE` is a `Sorted__<sample>.graph.methyl` from step 1,
`PRECOMPUTEDDB` is `Annotations.converted.db`, and `METHYLCOUTPUT` replaces the
`.graph.methyl` suffix with `.methylC`. 10 lines.

```bash
cd "$WORKDIR"

ln -s "$CONVERSION_DB" Annotations.converted.db

sbatch --array=1-10%10 "$CONVERT_BATCH" conversion_params.txt

mkdir -p Sorted_graph.methylC
mv Sorted__*.methylC Sorted_graph.methylC/
```

## 3. Filter on the conversion flag

Column 8 of the `.methylC` output is a bitwise flag describing how the site
converted. Only these values are retained:

```
1, 3, 5, 7, 9, 11, 13, 15, 34, 38, 42, 46
```

> The bit-level meaning of these flags is defined by the Ixchel conversion
> step. Inspect the distribution with
> `cut -f8 Sorted__*.methylC | sort | uniq -c` before changing the set.

```bash
cd "$WORKDIR/Sorted_graph.methylC"

for i in Sorted__*.methylC; do
  awk -F'\t' 'BEGIN{OFS="\t"}
    ($8==1||$8==3||$8==5||$8==7||$8==9||$8==11||$8==13||$8==15||
     $8==34||$8==38||$8==42||$8==46)' "$i" \
  > "${i%.methylC}.filtered.methylC"
done

mkdir -p "$WORKDIR/Filtered_Sorted_methylC"
mv Sorted__*.filtered.methylC "$WORKDIR/Filtered_Sorted_methylC/"
```

## 4. Strip the PanSN prefix from contig names

Surjected contigs carry the graph's PanSN naming (`C57BL_6_T2T_Yu#0#chr1`),
which will not match a plain mT2T annotation.

```bash
cd "$WORKDIR/Filtered_Sorted_methylC"

for i in Sorted__*.filtered.methylC; do
  awk -F'\t' 'BEGIN{OFS="\t"} {sub("C57BL_6_T2T_Yu#0#", "", $1); print}' "$i" \
  > "${i%.filtered.methylC}.filtered.cleaned.methylC"
done
```

## 5. Re-sort, compress and index

> Surjection does not preserve sort order. The inputs were sorted in step 1,
> but the converted output is in graph order and must be re-sorted on
> reference coordinates before tabix will index it.

```bash
cd "$WORKDIR/Filtered_Sorted_methylC"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools/5xvuvgk )   # samtools, version not recorded (build hash 5xvuvgk)

TMPDIR_SORT=$(mktemp -d)

for f in *.filtered.cleaned.methylC; do
  LC_ALL=C sort -T "$TMPDIR_SORT" -t $'\t' -k1,1 -k2,2n -k3,3n "$f" \
  | bgzip -@ 8 -c > "${f}.gz"
  tabix -f -p bed "${f}.gz"
done

rm -rf "$TMPDIR_SORT"
rm -f Sorted__*.filtered.methylC ./*.filtered.cleaned.methylC
```

`LC_ALL=C` is required: a locale-aware collation orders contig names
differently and produces an index that does not match the file.
