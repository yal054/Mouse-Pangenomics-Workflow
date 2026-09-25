# Retrieve and personalize DO low-coverage WGS

Downloads the 48 low-coverage (1–5×) Diversity Outbred WGS libraries, trims
them, and runs pangenome personalization for the low-coverage arm of the DO
paired-coverage comparison.

Data from Widmayer et al., *Mamm. Genome* (2025),
[doi:10.1007/s00335-025-10148-6](https://doi.org/10.1007/s00335-025-10148-6).

Same procedure as `Download_and_personalized_with_hc_DO_WGS.md`, with two
differences: 48 libraries rather than 10, and cutadapt rather than fastp.
These libraries showed adapter contamination but not the poly-G artifact that
required fastp on the high-coverage arm.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `GRAPH_PREFIX_CLIP` | clipped founder graph prefix |
| `GRAPH_PREFIX_FULL` | full founder graph prefix |
| `SRA_BATCH`, `FQDUMP_BATCH`, `BGZIP_BATCH`, `FASTQC_BATCH`, `CUTADAPT_BATCH` | batch wrappers |
| `KMC_SH`, `PERSONALIZE_SH` | `run_kmc.sh`, `submit_personalization_all.sh` |

```bash
WORKDIR=/path/to/DO_Personalizaiton/lcWGS
GRAPH_PREFIX_CLIP=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.
GRAPH_PREFIX_FULL=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.
```

## Accessions

48 libraries, `SRR33438147` through `SRR33438194` inclusive.

> Only 10 of the 48 animals have a matched high-coverage library; the paired
> comparison uses those 10 pairs.

## 1. Retrieve from SRA and extract FASTQ

```bash
mkdir -p "$WORKDIR/Raw_Data"
cd "$WORKDIR"

seq 33438147 33438194 | sed 's/^/SRR/' > Accessions_lcWGS.txt
wc -l Accessions_lcWGS.txt      # 48

sbatch --array=1-48%10 "$SRA_BATCH" Accessions_lcWGS.txt

mkdir -p lcWGS_SRAs
find SRR* -type f -exec mv {} lcWGS_SRAs/ \;
rm -rf SRR*

sbatch --array=1-48%5 "$FQDUMP_BATCH" lcWGS_SRAs_Files.txt

mv ./*.fastq Raw_Data/
```

`run_Batch_fasterqdump.sh` reads one path per line from `lcWGS_SRAs_Files.txt`:
one `.sra` file under `lcWGS_SRAs/`. 48 lines.

## 2. Compress and QC

Paired-end, so 96 FASTQ files from 48 libraries.

`run_Batch_bgzip.sh` reads one uncompressed FASTQ path per line from
`lcWGS_FastQ_Compression.txt` (`INPUT`). 96 lines, one per file in `Raw_Data/`.

`run_Batch_FastQC.sh` reads one line per FASTQ from `FastQC_Parameters.txt`, tab-separated:
`INPUT  OUTPUTDIRECTORY`
INPUT is a `.fastq.gz` in `Raw_Data/`; OUTPUTDIRECTORY is where FastQC writes its report. 96 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-96%10 "$BGZIP_BATCH" lcWGS_FastQ_Compression.txt
sbatch --array=1-96%10 "$FASTQC_BATCH" FastQC_Parameters.txt
```

## 3. Trim adapters with cutadapt

One task per library, both mates together.

| Parameter | Value |
|---|---|
| Adapter (both mates) | `CTGTCTCTTATACACATCT` (Nextera / Tn5) |
| Quality cutoff | `15,10` (5' , 3') |
| Minimum length | 36 bp |

`run_Batch_Cutadapt.sh` reads one line per library from `Cutadapt_Parameters.txt`:
`READ1  READ2  OUTPUT1  OUTPUT2  TRIMLOG`
48 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-48%48 "$CUTADAPT_BATCH" Cutadapt_Parameters.txt
```

## 4. Count k-mers and personalize

```bash
cd "$WORKDIR"

bash "$KMC_SH" \
  -i "$WORKDIR/Trimmed_lcWGS_FastQs" \
  -o "$WORKDIR/kmc_lcWGS" \
  --max-concurrent 5

bash "$PERSONALIZE_SH" \
  -k "$WORKDIR/kmc_lcWGS" \
  -o "$WORKDIR/Personalization_results" \
  --clip-prefix "$GRAPH_PREFIX_CLIP" \
  --full-prefix "$GRAPH_PREFIX_FULL" \
  --max-concurrent 5
```

Continue in `Merge_DO_lcWGS_personalized_walks_into_full_graph.md`.
