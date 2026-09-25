# Mapping accuracy: mT2T

Scores read-placement accuracy for simulated reads aligned to the C57BL/6J mT2T
assembly with BWA.

Shared steps, including the four subsample levels and the accuracy-table
combination, are described in `Calculate_mapping_accuracy.md`.

## What differs from the GRCm38 arm

1. Read groups are added first. The mT2T alignments arrive without read
   groups, and the accuracy workflow separates the two members of each F1 pair
   by read group.
2. The liftover indices are the mT2T ones: `Genome_Alignments_T2T/*_alignTo_mT2T.paf.rfx`, from
   `Prepare_genome_alignments_T2T.md`.

Working files are suffixed `_mT2T_BWA`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory, shared with the other arms |
| `SRC_BAMS` | simulated mT2T alignments |
| `PAF_DIR` | `Genome_Alignments_T2T/`, the mT2T liftover indices |
| `ADDRG_BATCH` | `run_Batch_Add_RG.sh` |

```bash
WORKDIR=/path/to/Mapping_Accuracy_Analysis
SRC_BAMS=/path/to/alignments/linear/Yu-T2T
PAF_DIR="$WORKDIR/Genome_Alignments_T2T"
ADDRG_BATCH=run_Batch_Add_RG.sh
```

## 1. Add read groups

Read-group fields are derived from the filename. The second dot-delimited field
carries the line name, with a `-query` suffix to strip.

Target form, for line CC001:

```
ID:CC001-lib1  PU:CC001-lib1  SM:CC001  PL:ILLUMINA  LB:CC001-lib1
```

`run_Batch_Add_RG.sh` reads one line per BAM from `Add_RG_to_BAM_parameters.txt`, tab-separated:
`INPUT  OUTPUT  RGID  RGPU  RGSM  RGPL  RGLB`
INPUT is a BAM in `bams_mT2T_BWA/`, OUTPUT is the same path ending in `.addedRG.bam`, and the read-group columns follow the target form above. 40 lines, one per RI line.

```bash
mkdir -p "$WORKDIR/bams_mT2T_BWA"
cd "$WORKDIR"

cp "$SRC_BAMS"/*.bam bams_mT2T_BWA/

sbatch --array=1-40%10 "$ADDRG_BATCH" Add_RG_to_BAM_parameters.txt
```

> Test this on a single BAM before running the full array. A wrong field offset
> produces read groups that look plausible but do not match what the workflow
> expects, and the failure only surfaces later as an empty accuracy table.

## 2. Subsample

`run_Batch_samtools_subsample.sh` reads one line per BAM and subsample level from `subsample_parameters_mT2T_BWA.txt`, tab-separated:
`INPUT  OUTPUT  FRACTION`
INPUT is a `*.addedRG.bam` in `bams_mT2T_BWA/`, OUTPUT is `<name>_<label>.bam` (for example `<name>_2pct.bam`), and FRACTION is 0.0025, 0.005, 0.01 or 0.02 for the labels `025pct`, `05pct`, `1pct` and `2pct`. 80 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-80%40 "$SUBSAMPLE_BATCH" subsample_parameters_mT2T_BWA.txt

mkdir -p bams_subsampled_mT2T_BWA && mv ./*.bam bams_subsampled_mT2T_BWA/
```

## 3. Index the mT2T liftover PAFs

`run_Batch_refract_build-liftover-index.sh` reads one line per PAF from `refract_index_parameters_T2T.txt`, tab-separated:
`PAF  INDEX`
PAF is the file name of a `*_alignTo_mT2T.paf` in `Genome_Alignments_T2T/`, and INDEX is that name with `.rfx` appended. 40 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-40%40 "$RFX_INDEX_BATCH" refract_index_parameters_T2T.txt
```

## 4. Build the workflow configuration

Uses the mT2T index paths.

`construct_mapping_accuracy_configs.py` reads one line per subsampled BAM from `Mapping_Accuracy_mT2T_BWA_SnakeMake_Parameters.txt`, tab-separated:
`BAM  RG1  PAF1  RG2  PAF2`
BAM is a file in `bams_subsampled_mT2T_BWA/` named `<A>-<B>_...`; RG1 is `<A>-lib1` and PAF1 is `Genome_Alignments_T2T/<A>_alignTo_mT2T.paf.rfx`, and RG2 and PAF2 are the same for `<B>`. 80 lines.

```bash
cd "$WORKDIR"

python3 "$CONFIG_PY" Mapping_Accuracy_mT2T_BWA_SnakeMake_Parameters.txt
```

## 5. Run and combine

```bash
cd "$WORKDIR"

sbatch --array=1-80%20 "$ACCURACY_BATCH" \
  Mapping_Accuracy_mT2T_BWA_SnakeMake_Parameters.txt

mkdir -p Workflow_directories_mT2T_BWA
mv CC*pct Workflow_directories_mT2T_BWA/
```

Combine as in `Calculate_mapping_accuracy.md` step 6, pointing the loop at
`Workflow_directories_mT2T_BWA/`.

Visualized in `Calculate_mapping_accuracy_mT2T_BWA.Rmd`.
