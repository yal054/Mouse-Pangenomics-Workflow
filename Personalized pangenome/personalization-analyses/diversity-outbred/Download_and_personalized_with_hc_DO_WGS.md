# Retrieve and personalize DO high-coverage WGS

Downloads the 10 high-coverage (30–60×) Diversity Outbred WGS libraries, trims
them, and runs pangenome personalization for the high-coverage arm of the DO
paired-coverage comparison.

Data from Widmayer et al., *Mamm. Genome* (2025),
[doi:10.1007/s00335-025-10148-6](https://doi.org/10.1007/s00335-025-10148-6).

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `GRAPH_PREFIX_CLIP` | clipped founder graph prefix |
| `GRAPH_PREFIX_FULL` | full founder graph prefix |
| `SRA_BATCH`, `FQDUMP_BATCH`, `BGZIP_BATCH`, `FASTQC_BATCH`, `FASTP_BATCH` | batch wrappers |
| `KMC_SH`, `PERSONALIZE_SH` | `run_kmc.sh`, `submit_personalization_all.sh` |

```bash
WORKDIR=/path/to/DO_Personalizaiton/hcWGS
GRAPH_PREFIX_CLIP=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.
GRAPH_PREFIX_FULL=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.
```

## Accessions

10 libraries:

```
SRR33939696  SRR33939697  SRR33939698  SRR33939699  SRR33939700
SRR33939701  SRR33939702  SRR33939703  SRR33939704  SRR33939705
```

These are the high-coverage members of the paired set; the matching
low-coverage libraries are in
`Download_and_personalized_with_lc_DO_WGS.md`.

## 1. Retrieve from SRA and extract FASTQ

```bash
mkdir -p "$WORKDIR/Raw_Data"
cd "$WORKDIR"

cat > Accessions_hcWGS.txt <<'EOF'
SRR33939696
SRR33939697
SRR33939698
SRR33939699
SRR33939700
SRR33939701
SRR33939702
SRR33939703
SRR33939704
SRR33939705
EOF

sbatch --array=1-10%5 "$SRA_BATCH" Accessions_hcWGS.txt

mkdir -p hcWGS_SRAs
find SRR* -type f -exec mv {} hcWGS_SRAs/ \;
rm -rf SRR*

sbatch --array=1-10%5 "$FQDUMP_BATCH" hcWGS_SRAs_Files.txt

mv ./*.fastq Raw_Data/
```

`run_Batch_fasterqdump.sh` reads one path per line from `hcWGS_SRAs_Files.txt`:
one `.sra` file under `hcWGS_SRAs/`. 10 lines.

## 2. Compress and QC

Paired-end, so 20 FASTQ files from 10 libraries.

`run_Batch_bgzip.sh` reads one uncompressed FASTQ path per line from
`hcWGS_FastQ_Compression.txt` (`INPUT`). 20 lines, one per file in `Raw_Data/`.

`run_Batch_FastQC.sh` reads one line per FASTQ from `FastQC_Parameters.txt`, tab-separated:
`INPUT  OUTPUTDIRECTORY`
INPUT is a `.fastq.gz` in `Raw_Data/`; OUTPUTDIRECTORY is where FastQC writes its report. 20 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-20%20 "$BGZIP_BATCH" hcWGS_FastQ_Compression.txt
sbatch --array=1-20%10 "$FASTQC_BATCH" FastQC_Parameters.txt
```

## 3. Trim with fastp

> FastQC showed both adapter contamination and over-represented poly-G. Poly-G is a two-colour-chemistry artifact, which
> cutadapt does not remove; fastp trims it directly. The low-coverage arm of
> this study did not show it and used cutadapt.

| Parameter | Value |
|---|---|
| Adapter (both mates) | `CTGTCTCTTATACACATCT` (Nextera / Tn5) |
| Sliding-window trim | `-5 -3`, window size 1 |
| Mean quality, front / tail | 15 / 10 |
| Poly-G trimming | enabled (fastp default for two-colour data) |

`run_Batch_fastp.sh` reads one line per library from `FastP_Parameters.txt`:
`READ1  READ2  OUTPUT1  OUTPUT2  TRIMLOG`
10 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-10%10 "$FASTP_BATCH" FastP_Parameters.txt
```

> One library needed more memory than the default and was resubmitted
> individually with `--mem=32G`. If a task fails, rerun that index alone rather
> than raising memory for all ten.

## 4. Count k-mers and personalize

```bash
cd "$WORKDIR"

bash "$KMC_SH" \
  -i "$WORKDIR/Trimmed_hcWGS_FastQs" \
  -o "$WORKDIR/kmc_hcWGS" \
  --max-concurrent 5

bash "$PERSONALIZE_SH" \
  -k "$WORKDIR/kmc_hcWGS" \
  -o "$WORKDIR/Personalization_results" \
  --clip-prefix "$GRAPH_PREFIX_CLIP" \
  --full-prefix "$GRAPH_PREFIX_FULL" \
  --max-concurrent 5
```

Continue in `Merge_DO_hcWGS_personalized_walks_into_full_graph.md`.
