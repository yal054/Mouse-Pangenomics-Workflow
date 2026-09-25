# Personalize the downsampled RI libraries

Runs k-mer counting and pangenome personalization on each downsampled RI
library, giving one personalized graph per line per coverage level.

Second step of the saturation analysis, between `Downsample_RI_data.md` and
`Merge_Saturation_personalized_walks_into_full_graph.md`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `DOWNSAMPLED` | downsampled FASTQ files from `Downsample_RI_data.md` |
| `GRAPH_PREFIX_CLIP` | clipped founder graph prefix |
| `GRAPH_PREFIX_FULL` | full founder graph prefix |
| `KMC_ARRAY` | `run_kmc_array.sh` |
| `PERSONALIZE_ARRAY` | `submit_personalization_array.sh` |

```bash
WORKDIR=/path/to/Saturation_analysis
DOWNSAMPLED="$WORKDIR/Downsampled_data"
GRAPH_PREFIX_CLIP=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.
GRAPH_PREFIX_FULL=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.
KMC_ARRAY=../run_kmc_array.sh
PERSONALIZE_ARRAY=../submit_personalization_array.sh
```

> The graph prefixes are passed as prefixes, not filenames. The
> personalization scripts append their own suffixes to locate the graph, its
> indices and the haplotype information.

## Outputs

`Personalization_results/full/<line>__<fraction>__samples/`, one personalized
graph per line per downsample fraction (120 in total).

## 1. Count k-mers

```bash
mkdir -p "$WORKDIR/kmc_downsampled_RI_WGS"
cd "$WORKDIR"

bash "$KMC_ARRAY" \
  -i "$DOWNSAMPLED" \
  -o "$WORKDIR/kmc_downsampled_RI_WGS" \
  --max-concurrent 5
```

## 2. Personalize

```bash
mkdir -p "$WORKDIR/Personalization_results"
cd "$WORKDIR"

bash "$PERSONALIZE_ARRAY" \
  -k "$WORKDIR/kmc_downsampled_RI_WGS" \
  -o "$WORKDIR/Personalization_results" \
  --clip-prefix "$GRAPH_PREFIX_CLIP" \
  --full-prefix "$GRAPH_PREFIX_FULL" \
  --max-concurrent 5
```

Check that every run produced a log of the same length; an unexpected line
count indicates a failed run:

```bash
cd "$WORKDIR"
find . -type f -name "*.out" -exec wc -l {} \; | cut -d" " -f1 | sort | uniq -c
```

## 3. Reduce the output footprint

Personalization writes uncompressed intermediates that are large at this scale.

> The clipped results are not kept. Only the full graph is used downstream,
> and clipping can be redone from it if needed.

```bash
cd "$WORKDIR/Personalization_results"
rm -rf clip/

cd "$WORKDIR/Personalization_results/full"

# the unfiltered read FASTAs are intermediates
rm -f ./*/r1.fasta ./*/r2.fasta

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)

for f in ./*/r1f.fasta ./*/r2f.fasta ./*/*.vcf; do
    [ -e "$f" ] || continue
    echo "Compressing $f"
    bgzip -@ 12 "$f"
done
```

Continue in `Merge_Saturation_personalized_walks_into_full_graph.md`.

> Once the traversals have been extracted and merged there, the k-mer databases
> and the personalization working directories can be removed: the GBWTs carry
> everything needed downstream, and FASTAs or VCFs can be regenerated from the
> merged graph.
