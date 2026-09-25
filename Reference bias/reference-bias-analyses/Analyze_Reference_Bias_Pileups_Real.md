# Reference bias from real-animal pileups

Parses the variant pileups for the real CC RI WGS libraries and joins them per
site, giving a paired reference fraction on GRCm38 and on the Founder Pangenome
for every heterozygous site.

The real-data counterpart of `Analyze_Reference_Bias_Pileups.md`. Feeds
`Visualize_Reference_Alignment_Bias_Real.Rmd`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `BWA_PILEUPS` | pileups from BWA alignment to GRCm38 |
| `PG_PILEUPS` | pileups from Founder Pangenome alignment, surjected |
| `PARSE_BATCH` | `run_Batch_parse_ref_bias_vcf.sh` |
| `MERGE_BATCH` | `run_Batch_merge_parsed_ref_bias_vcf__two-way-comparison.sh` |

```bash
WORKDIR=/path/to/Reference_Bias/Real_Animals
BWA_PILEUPS=/path/to/Reference_Bias/BWA_Variant_Pileups
PG_PILEUPS=/path/to/Reference_Bias/Pangenome_Variant_Pileups
PARSE_BATCH=run_Batch_parse_ref_bias_vcf.sh
MERGE_BATCH=run_Batch_merge_parsed_ref_bias_vcf__two-way-comparison.sh
```

## Telling real from simulated

Both arms live in the same pileup directories, distinguished only by filename:

| Pattern | Which |
|---|---|
| `CC0<line>-CC0<line>.intersected.vcf.gz` | **simulated**: two RI names, an in-silico F1 cross |
| `CC0<line>.intersected.vcf.gz` | **real**: one RI name, a sequenced animal |

Everything below uses the single-name files. The pileups
themselves were produced upstream by a co-author.

## Outputs

`Merged_Parsed_VCFs/*.mergedParsed.bed.gz`, per-site paired reference
fractions.

## 1. Parse each pileup to per-site allele depths

One task per pileup file, across both references.

`run_Batch_parse_ref_bias_vcf.sh` reads one line per pileup from
`parse_params.txt`, tab-separated:
`INPUT  OUTPUT`
`INPUT` is a real-animal pileup (`CC0<line>.intersected.vcf.gz`, one RI name,
no `-`) from `$BWA_PILEUPS` or `$PG_PILEUPS`, and `OUTPUT` is its basename with
`.intersected.vcf.gz` replaced by `.parsed.bed` and prefixed `BWA_` or
`Pangenome_`. 80 lines: 40 animals x 2 references.

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

sbatch --array=1-80%80 "$PARSE_BATCH" parse_params.txt
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
per animal from `merge_params.txt`, tab-separated:
`INPUT1  INPUT2  OUTPUT`
`INPUT1` is the animal's `Parsed_VCFs/Pangenome_<animal>.parsed.bed.gz`,
`INPUT2` its BWA counterpart `Parsed_VCFs/BWA_<animal>.parsed.bed.gz`, and
`OUTPUT` is `<animal>.mergedParsed.bed.gz`. 40 lines, one per parsed animal;
the real-data arm merges 20 of them (array `1-20`, see note).

```bash
cd "$WORKDIR"

sbatch --mem=20G --array=1-20%20 "$MERGE_BATCH" merge_params.txt
```

> The real-data arm is 20 animals. The parameters file is built from all
> available parsed files and holds more rows than that, so the array is
> submitted as `1-20`. Adjust the range if you extend the arm.

## 4. Collect the merged output

```bash
cd "$WORKDIR"
mkdir -p Merged_Parsed_VCFs
mv ./*.mergedParsed.bed.gz Merged_Parsed_VCFs/
```
