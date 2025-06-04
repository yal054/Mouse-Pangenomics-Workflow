# ATAC-seq Peak Analysis Pipeline

This repository contains a modular pipeline for allele-specific ATAC-seq peak analysis using pangenome graph alignment. The pipeline includes read alignment, peak calling, normalization, differential accessibility testing, and functional annotation.

## Pipeline Overview

| Step | Script              | Description                                                                                      |
|------|---------------------|--------------------------------------------------------------------------------------------------|
| 1️⃣   | `0.mapping.sh`       | Perform QC on raw ATAC-seq reads, clean them, and align to the mouse CC pangenome graph using `vg giraffe`. |
| 2️⃣   | `1.call_peak.sh`     | Project mapped reads to GRCm38, CC032, and CC072. Call peaks on GRCm38 using 2 biological replicates and identify reproducible peaks using naive peak intersection strategy. |
| 3️⃣   | `2.spm.py`           | Normalize signal to signal-per-million (SPM) to filter high-confidence peaks.                  |
| 4️⃣   | `3.extract_count.sh` | Phase GRCm38-aligned reads to CC032 and CC072 haplotypes and extract peak-level counts per strain. |
| 5️⃣   | `4.DEpeaks.R`        | Perform differential peak analysis using `DESeq2`, comparing CC032 (case) vs. CC072 (control). |
| 6️⃣   | `5.rGREAT.R`         | Run `rGREAT` to perform functional enrichment analysis on differential peaks.                 |
| 7️⃣   | `6.annotation.sh`    | Annotate differential peaks with genomic features using `HOMER`.                              |

## Requirements

- `vg`, `samtools`, `bedtools`
- `MACS2`
- `R` packages: `DESeq2`, `rGREAT`,  `tidyverse`
- Optional: `HOMER` for annotation

