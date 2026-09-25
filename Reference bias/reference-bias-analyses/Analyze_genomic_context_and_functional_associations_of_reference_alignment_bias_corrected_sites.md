# Genomic context of bias-corrected sites

Identifies the sites where the Founder Pangenome corrects reference bias present
on GRCm38, and annotates their genomic and gene context with HOMER.

Runs on the in-silico F1 crosses.

## What "bias-corrected" means here

A site is bias-corrected if the pangenome rebalances an allele ratio that GRCm38
skews:

| Reference | Criterion |
|---|---|
| Founder Pangenome | reference fraction **> 0.4 and < 0.6**, balanced |
| GRCm38 | reference fraction **> 0.7**, or `NA` | 

`NA` on GRCm38 counts as biased: a site with no GRCm38 call is the extreme case
of reference bias, not a missing observation.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `MERGED_DIR` | `Merged_Parsed_VCFs/` from `Analyze_Reference_Bias_Pileups.md` |
| `HOMER_BATCH` | `run_Batch_annotatePeaks.sh` |

```bash
WORKDIR=/path/to/Analyze_genomic_context_of_bias_corrected_sites
MERGED_DIR=/path/to/Reference_Bias/Merged_Parsed_VCFs
HOMER_BATCH="../../Functional genomics/functional-analyses/Regulatory-variation/run_Batch_annotatePeaks.sh"
```

### Column layout of the merged files

`chrom | start | end | pangenome_ref_fraction | F1_ref_fraction | GRCm38_ref_fraction | diff_1_2 | diff_1_3`

Columns 4 and 6 are the two the filter acts on.

## Outputs

`Annotated_Sites/<category>/<category>.Annotations`, HOMER annotation per
category.

## 1. Filter to bias-corrected sites, per cross

```bash
mkdir -p "$WORKDIR/Filtered_Sites"
cd "$WORKDIR"

mkdir -p Merged_Parsed_VCFs
ln -s "$MERGED_DIR"/* Merged_Parsed_VCFs/

for file in Merged_Parsed_VCFs/*.bed.gz; do
    cross=$(basename "$file" .mergedParsed.bed.gz)
    echo "$cross"
    gzip -cd "$file" \
    | awk 'NR==1 || ($4 > 0.4 && $4 < 0.6 && ($6 > 0.7 || $6 == "NA"))' \
    > "Filtered_Sites/${cross}.filtered.bed"
done

wc -l Filtered_Sites/*.filtered.bed
```

Each cross gives just under a million sites.

## 2. Strip headers and sort

```bash
cd "$WORKDIR"
mkdir -p Cleaned_BEDs

for f in Filtered_Sites/*.filtered.bed; do
    cross=$(basename "$f" .filtered.bed)
    tail -n +2 "$f" | cut -f1-3 | sort -k1,1 -k2,2n > "Cleaned_BEDs/${cross}.sorted.bed"
done
```

## 3. Merge into a union interval set

```bash
cd "$WORKDIR"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh bedtools2/f3mnrck )   # bedtools2 2.30.0 (build hash f3mnrck)

cat Cleaned_BEDs/*.bed | sort -k1,1 -k2,2n > all_sites.sorted.bed
bedtools merge -i all_sites.sorted.bed > all_sites_merged.bed
```

## 4. Determine which crosses share each interval

`bedtools multiinter` reports, per sub-interval, how many of the input files
cover it and which ones.

```bash
cd "$WORKDIR"

eval $( spack load --sh bedtools2/f3mnrck )   # bedtools2 2.30.0 (build hash f3mnrck)

bedtools multiinter -i all_sites_merged.bed -i Cleaned_BEDs/*.bed > multiinter.bed
```

Output columns:

| Column | Contents |
|---|---|
| 1–3 | chrom, start (0-based), end |
| 4 | number of input files overlapping this sub-interval |
| 5 | list of overlapping file numbers, in command-line order |
| 6+ | one 0/1 column per input file |

The per-file columns are positional, so record which file is which:

```bash
cd "$WORKDIR"

printf '%s\n' Cleaned_BEDs/*.sorted.bed \
| sed -e 's|Cleaned_BEDs/||' -e 's|.sorted.bed||' \
| nl -w1 -s $'\t' > multiinter_file_index_map.txt
```

## 5. Partition into categories

> Column 4 counts the merged union file as well as the per-cross files. The
> union is passed as the first `-i`, so N crosses shared corresponds to
> `$4 == N+1`, not `$4 == N`.

Categories:

| Category | Definition |
|---|---|
| `N_cross_shared` | intervals covered by exactly N crosses (`$4 == N+1`) |
| `N_cross_cumulative` | covered by at least N crosses |
| `N_cross_decreasing` | covered by at most N crosses |
| `<cross>_individual` | covered by that specific cross (its own 0/1 column ≥ 1) |
| `All_sites` | the whole `multiinter.bed` |

```bash
cd "$WORKDIR"

for n in $(seq 1 20); do
    mkdir -p "Annotated_Sites/${n}_cross_shared"
    awk -v k=$((n+1)) '$4==k' multiinter.bed \
      > "Annotated_Sites/${n}_cross_shared/${n}_cross_shared.bed"
done

mkdir -p Annotated_Sites/All_sites
cp multiinter.bed Annotated_Sites/All_sites/all_sites.bed
```

Per-cross individual sets select on that cross's own 0/1 column, which starts at
column 6 in file-index order.

## 6. Annotate every category with HOMER

`run_Batch_annotatePeaks.sh` reads one line per category from
`Homer_annotate_params.txt`, tab-separated:
`INPUTPEAKFILE  GENOME  OUTPUTANNOTATIONS`
`INPUTPEAKFILE` is a category BED under `Annotated_Sites/`, `GENOME` is `mm10`,
and `OUTPUTANNOTATIONS` is the same path with `.bed` replaced by `.Annotations`.
87 lines, one per category.

```bash
cd "$WORKDIR"

# Resources used: 28 GB per task, 40 concurrent
sbatch --array=1-87%40 --mem=28G "$HOMER_BATCH" Homer_annotate_params.txt
```

Gene and genomic annotation composition, overall, by degree of cross-sharing,
and per cross, is plotted in
`Analyze_genomic_context_and_functional_associations_of_reference_alignment_bias_corrected_sites.Rmd`.
