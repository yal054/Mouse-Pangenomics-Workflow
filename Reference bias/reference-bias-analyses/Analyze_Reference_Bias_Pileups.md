# Reference bias from in-silico F1 pileups

Parses the variant pileups for the 20 in-silico F1 crosses and joins them per
site, giving a paired reference fraction on GRCm38 and on the Founder Pangenome
for every heterozygous site.

Feeds `Visualize_Reference_Alignment_Bias.Rmd`. The real-data
counterpart is `Analyze_Reference_Bias_Pileups_Real.md`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `BWA_PILEUPS` | pileups from BWA alignment to GRCm38 |
| `PG_PILEUPS` | pileups from Founder Pangenome alignment, surjected |
| `PARSE_BATCH` | `run_Batch_parse_ref_bias_vcf.sh` |
| `MERGE_BATCH` | `run_Batch_merge_parsed_ref_bias_vcf__two-way-comparison.sh` |

```bash
WORKDIR=/path/to/Reference_Bias
BWA_PILEUPS="$WORKDIR/BWA_Variant_Pileups"
PG_PILEUPS="$WORKDIR/Pangenome_Variant_Pileups"
PARSE_BATCH=run_Batch_parse_ref_bias_vcf.sh
MERGE_BATCH=run_Batch_merge_parsed_ref_bias_vcf__two-way-comparison.sh
```

## Telling simulated from real

Both arms live in the same pileup directories, distinguished only by filename:

| Pattern | Which |
|---|---|
| `CC0<line>-CC0<line>.intersected.vcf.gz` | **simulated**: two RI names, an in-silico F1 cross |
| `CC0<line>.intersected.vcf.gz` | **real**: one RI name, a sequenced animal |

This protocol selects the two-name files. The F1 graphs those crosses were
called against are built in `Build_F1_Graphs_from_haploids.md`.

## Outputs

`Merged_Parsed_VCFs/*.mergedParsed.bed.gz`, per-site paired reference
fractions, and `reference_fraction_threshold_counts.tsv`.

## 1. Parse each pileup to per-site allele depths

`run_Batch_parse_ref_bias_vcf.sh` reads one line per pileup from
`parse_params.txt`, tab-separated:
`INPUT  OUTPUT`
`INPUT` is a simulated-cross pileup (`CC0<line>-CC0<line>.intersected.vcf.gz`)
from `$BWA_PILEUPS` or `$PG_PILEUPS`, and `OUTPUT` is its basename with
`.intersected.vcf.gz` replaced by `.parsed.bed` and prefixed `BWA_` or
`Pangenome_`. 40 lines: 20 crosses x 2 references.

```bash
cd "$WORKDIR"

sbatch --array=1-40%40 "$PARSE_BATCH" parse_params.txt
```

## 2. Collect and compress

```bash
cd "$WORKDIR"

mkdir -p Parsed_VCFs
mv ./*.bed Parsed_VCFs/

cd Parsed_VCFs
for file in *.bed; do
    pigz -p 8 -c "$file" > "$file.gz"
done
rm -f ./*.bed
```

## 3. Join the two references per site

`run_Batch_merge_parsed_ref_bias_vcf__two-way-comparison.sh` reads one line
per cross from `merge_params.txt`, tab-separated:
`INPUT1  INPUT2  OUTPUT`
`INPUT1` is the cross's `Parsed_VCFs/Pangenome_<cross>.parsed.bed.gz`, `INPUT2`
its BWA counterpart `Parsed_VCFs/BWA_<cross>.parsed.bed.gz`, and `OUTPUT` is
`<cross>.mergedParsed.bed.gz`. 20 lines, one per cross.

```bash
cd "$WORKDIR"

sbatch --mem=20G --array=1-20%20 "$MERGE_BATCH" merge_params.txt

mkdir -p Merged_Parsed_VCFs
mv ./*.mergedParsed.bed.gz Merged_Parsed_VCFs/
```

## 4. Count strongly biased sites by threshold

Column 4 is the Pangenome reference fraction, column 6 the BWA one. This counts
the sites above each threshold per cross and per reference.

```bash
cd "$WORKDIR/Merged_Parsed_VCFs"

printf "file\tGenome\treferenceFraction\tn_sites_above_threshold\n" \
  > reference_fraction_threshold_counts.tsv

for file in *.bed.gz; do
  for threshold in 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9; do
    gzip -cd "$file" | awk -v file="$file" -v threshold="$threshold" '
      BEGIN { FS = OFS = "\t" }
      {
        if ($4 > threshold) pangenome_count++;
        if ($6 > threshold) bwa_count++;
      }
      END {
        print file, "Pangenome", threshold, pangenome_count + 0;
        print file, "BWA", threshold, bwa_count + 0;
      }
    '
  done
done >> reference_fraction_threshold_counts.tsv
```
