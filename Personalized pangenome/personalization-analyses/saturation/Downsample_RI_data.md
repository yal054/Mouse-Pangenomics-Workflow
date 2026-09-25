# Downsample the RI libraries

Estimates the starting coverage of each CC RI library, then downsamples all 40
to one quarter, one eighth and one sixteenth of their reads.

First step of the saturation analysis, which measures the stability of
`vg haplotypes` path selection as a function of coverage.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `FASTQ_DIR` | source CC RI paired FASTQ files |
| `COV_BATCH` | `run_Batch_Calculate_expected_coverage_from_fastq.sh` |
| `SEQTK_BATCH` | `run_Batch_seqtk_sample.sh` |

```bash
WORKDIR=/path/to/Saturation_analysis
FASTQ_DIR=/path/to/short_read_CC
COV_BATCH=run_Batch_Calculate_expected_coverage_from_fastq.sh
SEQTK_BATCH=run_Batch_seqtk_sample.sh
```

## Parameters

| Parameter | Value |
|---|---|
| Read length | 151 bp |
| Genome size | 2.73e9 |
| Downsample fractions | 0.25, 0.125, 0.0625 |
| seqtk seed | 13 |

> The seed must be identical for R1 and R2 of a given sample and fraction.
> `seqtk sample` selects records by seed, so a differing seed between mates
> silently breaks pairing.

## Outputs

`Downsampled_data/<sample>__<fraction>__samples_R{1,2}.fastq.gz`, 240 files
(40 samples × 3 fractions × 2 mates).

## 1. Link the source libraries

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

for i in "$FASTQ_DIR"/*fastq.gz; do ln -s "$i" .; done
```

## 2. Estimate starting coverage

Coverage is estimated from read count: pairs × 2 × read length / genome size.
For a single library that is:

```bash
cd "$WORKDIR"
pigz -p 20 -dc CC001_R1.fastq.gz | awk 'END {pairs=NR/4; print pairs*302/2.73e9}'
```

Across all 40, as an array. `run_Batch_Calculate_expected_coverage_from_fastq.sh`
reads one line per R1 library from `CalcCov_params.txt`, tab-separated:
`FASTQ  READ_LENGTH  GENOME_SIZE  PAIRED`
`FASTQ` is the linked `*R1.fastq.gz` file name; the other columns are `151`,
`2.73e9` and `TRUE` on every line. 40 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-40%10 "$COV_BATCH" CalcCov_params.txt
```

Collect the per-sample results:

```bash
cd "$WORKDIR"
cat ./*.coverage > Original_coverage.txt
rm -f ./*.coverage
```

Mean starting coverage across the 40 libraries is 41.1×.

## 3. Downsample

`run_Batch_seqtk_sample.sh` reads one line per library, mate and fraction from
`Downsample_Parameters.txt`, tab-separated:
`INPUTFASTQ  SEED  FRACTION  OUTPUTFASTQ`
`SEED` is `13` on every line and `FRACTION` is one of 0.25, 0.125 and 0.0625.
`OUTPUTFASTQ` is `<sample>__<fraction>__samples_<R1|R2>.fastq.gz`, where
`<sample>` is the input file name up to its first `_`. Both mates and all three
fractions in one manifest, 240 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-240%50 "$SEQTK_BATCH" Downsample_Parameters.txt
```

## 4. Collect

```bash
cd "$WORKDIR"

mkdir -p Downsampled_data
mv ./*__samples_R*.fastq.gz Downsampled_data/

rm -f ./*.fastq.gz          # the source symlinks
```

The downsampled libraries are the input to `Personalize_downsampled_RI_WGS.md`.
