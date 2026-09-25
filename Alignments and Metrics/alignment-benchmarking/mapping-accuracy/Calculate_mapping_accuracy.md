# Mapping accuracy: GRCm38

Scores read-placement accuracy for simulated reads aligned to GRCm38, by
lifting each read back to the assembly it was simulated from and asking whether
it landed inside the lifted interval.

The mT2T and pangenome arms are
`Calculate_mapping_accuracy_mT2T_BWA.md` and `Calculate_mapping_accuracy_pan.md`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `SRC_BAMS` | simulated alignments to GRCm38, one per F1 pair |
| `PAF_DIR` | `Genome_Alignments/` from `Prepare_genome_alignments.md` |
| `SUBSAMPLE_BATCH` | `run_Batch_samtools_subsample.sh` |
| `RFX_INDEX_BATCH` | `run_Batch_refract_build-liftover-index.sh` |
| `CONFIG_PY` | `construct_mapping_accuracy_configs.py` |
| `ACCURACY_BATCH` | `run_mapping_accuracy.sh` |

```bash
WORKDIR=/path/to/Mapping_Accuracy_Analysis
SRC_BAMS=/path/to/alignments/linear/GRCm38/sim-merged
PAF_DIR="$WORKDIR/Genome_Alignments"
SUBSAMPLE_BATCH=run_Batch_samtools_subsample.sh
RFX_INDEX_BATCH=run_Batch_refract_build-liftover-index.sh
CONFIG_PY=construct_mapping_accuracy_configs.py
ACCURACY_BATCH=run_mapping_accuracy.sh
```

The simulated alignments were produced upstream by a co-author.

## Subsample levels

Accuracy is computed at four depths. 20 F1 pairs × 4 levels = 80 tasks.

| Label | Fraction |
|---|---|
| `025pct` | 0.0025 |
| `05pct` | 0.005 |
| `1pct` | 0.01 |
| `2pct` | 0.02 |

Subsampling uses `samtools view --subsample` with a fixed seed of 42, so the
same reads are drawn on every rerun and across the three reference arms.

> `Calculate_mapping_accuracy_Combined.Rmd` filters to the 2% subsample; the
> other levels check that the result does not depend on depth.

## Outputs

`Combined_saturation_metrics.txt`, accuracy tables from every run, annotated
with pair and subsample level.

## 1. Subsample the alignments

`run_Batch_samtools_subsample.sh` reads one line per BAM and subsample level from `subsample_parameters.txt`, tab-separated:
`INPUT  OUTPUT  FRACTION`
INPUT is a BAM in `bams/`, OUTPUT is `<name>_<label>.bam` (for example `<name>_2pct.bam`), and FRACTION is 0.0025, 0.005, 0.01 or 0.02 for the labels `025pct`, `05pct`, `1pct` and `2pct`. 80 lines.

```bash
mkdir -p "$WORKDIR/bams"
cd "$WORKDIR"

cp "$SRC_BAMS"/*.bam bams/

sbatch --array=1-80%40 "$SUBSAMPLE_BATCH" subsample_parameters.txt

mkdir -p bams_subsampled && mv ./*.bam bams_subsampled/
```

## 2. Index the liftover PAFs

One index per RI line, from the genome alignments prepared earlier.

`run_Batch_refract_build-liftover-index.sh` reads one line per PAF from `refract_index_parameters.txt`, tab-separated:
`PAF  INDEX`
PAF is the file name of a `*_alignTo_GRCm38.paf` in `Genome_Alignments/`, and INDEX is that name with `.rfx` appended. 40 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-40%40 "$RFX_INDEX_BATCH" refract_index_parameters.txt
```

## 3. Confirm read-group naming

Each F1 BAM carries reads from two lines, distinguished by read group. The
config builder derives read-group names from the filename, so they must match.

```bash
cd "$WORKDIR"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools@1.13/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)

for bam in bams_subsampled/*1pct.bam; do
    echo "=== $(basename "$bam") ==="
    samtools view -H "$bam" | grep '^@RG'
done
```

## 4. Build the workflow configuration

`construct_mapping_accuracy_configs.py` reads one line per subsampled BAM from `Mapping_Accuracy_SnakeMake_Parameters.txt`, tab-separated:
`BAM  RG1  PAF1  RG2  PAF2`
BAM is a file in `bams_subsampled/` named `<A>-<B>_...`; RG1 is `<A>-lib1` and PAF1 is `Genome_Alignments/<A>_alignTo_GRCm38.paf.rfx`, and RG2 and PAF2 are the same for `<B>`. 80 lines.

```bash
cd "$WORKDIR"

python3 "$CONFIG_PY" Mapping_Accuracy_SnakeMake_Parameters.txt
```

## 5. Run the accuracy workflow

```bash
cd "$WORKDIR"

sbatch --array=1-80%20 "$ACCURACY_BATCH" Mapping_Accuracy_SnakeMake_Parameters.txt

# one accuracy table per run; expect 80
ls -1 CC*pct/*.accuracy_table.tsv | wc -l

mkdir -p Workflow_directories && mv CC*pct Workflow_directories/
```

## 6. Combine the accuracy tables

Annotates each row with its run directory, pair and subsample level, keeping a
single header.

```bash
cd "$WORKDIR"

{
    first=1
    for f in $(printf '%s\n' Workflow_directories/CC*pct/*.accuracy_table.tsv | sort); do
        run_dir=$(basename "$(dirname "$f")")
        pair_name="${run_dir%_*}"
        subsample_label="${run_dir##*_}"
        case "$subsample_label" in
            025pct) subsample_percent="0.25" ;;
            05pct)  subsample_percent="0.5"  ;;
            1pct)   subsample_percent="1"    ;;
            2pct)   subsample_percent="2"    ;;
            *)      subsample_percent="NA"   ;;
        esac
        if [ "$first" -eq 1 ]; then
            printf "run_dir\tpair_name\tsubsample_label\tsubsample_percent\tsource_file\t"
            head -n 1 "$f"
            first=0
        fi
        awk -v run_dir="$run_dir" \
            -v pair_name="$pair_name" \
            -v subsample_label="$subsample_label" \
            -v subsample_percent="$subsample_percent" \
            -v source_file="$(basename "$f")" \
            'BEGIN{OFS="\t"} NR>1 {print run_dir, pair_name, subsample_label, subsample_percent, source_file, $0}' \
            "$f"
    done
} > Combined_saturation_metrics.txt
```

Visualized in `Calculate_mapping_accuracy_mm10.Rmd`, and combined across all
three references in `Calculate_mapping_accuracy_Combined.Rmd`.
