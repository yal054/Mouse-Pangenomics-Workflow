# HOMER annotation of variable cCREs

Annotates the candidate cis-regulatory elements carrying substantial variant
burden, assigning each to its nearest gene.

Feeds `HOMER_on_All_variable_cCREs_stats.Rmd` and the regulatory-variation
summaries.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | directory holding the cCRE burden table |
| `BURDEN_TSV` | `...intersect.mm10-cCRE_mutational_burden.tsv` from `Intersect_Variants_with_cCREs.md` |
| `HOMER_BATCH` | `run_Batch_annotatePeaks.sh` |

```bash
WORKDIR=/path/to/Intersect_Variants_with_cCREs
BURDEN_TSV="$WORKDIR/founder.plus_allCC.deconstruct.mm10.intersect.mm10-cCRE_mutational_burden.tsv"
HOMER_BATCH=run_Batch_annotatePeaks.sh
```

## Outputs

`variable_cCRE_format.HOMER.out`, HOMER annotation of the filtered cCREs, and
`variable_cCRE_format.HOMER.GeneID`, nearest-gene counts.

## 1. Reshape the burden table to BED

Carries the mutational-burden columns through so the filter below can act on
them.

```bash
cd "$WORKDIR"

cut -f1,2,3,4,5,13,14 "$BURDEN_TSV" \
| awk -F "\t" 'NR > 0 { print $1"\t"$2"\t"$3"\t"$1":"$2"-"$3"\t"$3"\t"$5"\t"$4"\t"$6"\t"$7 }' \
> variable_cCRE_format.bed
```

## 2. Filter to substantially variable cCREs

Retains elements where either burden measure (maximum ALT bp, or maximum
length difference) reaches the threshold.

```bash
cd "$WORKDIR"

awk -F "\t" 'NR > 0 && ($8 >= 25 || $9 >= 25) { print $0 }' \
  variable_cCRE_format.bed > variable_cCRE_format_filtered.bed

wc -l variable_cCRE_format*.bed
```

> The lab note gives the intended criterion as `burden_max_alt_bp >= 14` or
> `burden_max_len_diff_bp >= 20`, but the command that was run uses `>= 25`
> for both. The results come from `>= 25`. Confirm which was intended before
> reuse.

## 3. Annotate with HOMER

`run_Batch_annotatePeaks.sh` reads one line per peak file from `homer_params.txt`, tab-separated:
`INPUTPEAKFILE  GENOME  OUTPUTANNOTATIONS`
Here the peak file is `variable_cCRE_format_filtered.bed`, the genome `mm10`,
and the output `variable_cCRE_format.HOMER.out`. 1 line.

```bash
cd "$WORKDIR"

# Resources used: 16 GB, single task
sbatch --array=1-1%1 --mem=16G "$HOMER_BATCH" homer_params.txt
```

## 4. Summarize nearest genes

```bash
cd "$WORKDIR"

cut -f15 variable_cCRE_format.HOMER.out \
| grep -v "Nearest Ensembl" \
| sed 's/^$/NA/' \
| sort | uniq -c | grep -v "NA" \
> variable_cCRE_format.HOMER.GeneID
```
