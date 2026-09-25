# Mapping accuracy: Founder Pangenome

Scores read-placement accuracy for simulated reads aligned to the Founder
Pangenome with `vg giraffe` and surjected to linear coordinates.

Shared steps, including the four subsample levels and the accuracy-table
combination, are described in `Calculate_mapping_accuracy.md`.

## What differs from the GRCm38 arm

> The liftover indices are the GRCm38 ones. These alignments were surjected
> to GRCm38 coordinates after graph alignment, so reads are lifted back through
> the same `*_alignTo_GRCm38.paf.rfx` indices as the linear GRCm38 arm.

Working files are suffixed `_founder_Graph` so the three arms can coexist in one
directory.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory, shared with the other arms |
| `SRC_BAMS` | simulated Founder Pangenome alignments, surjected |
| `PAF_DIR` | `Genome_Alignments/`, the GRCm38 liftover indices |

```bash
WORKDIR=/path/to/Mapping_Accuracy_Analysis
SRC_BAMS=/path/to/alignments/graph/Founders/sim/alignments/sim-merged
PAF_DIR="$WORKDIR/Genome_Alignments"
```

## 1. Subsample

`run_Batch_samtools_subsample.sh` reads one line per BAM and subsample level from `subsample_parameters_founder_Graph.txt`, tab-separated:
`INPUT  OUTPUT  FRACTION`
INPUT is a BAM in `bams_founder_Graph/`, OUTPUT is `<name>_<label>.bam` (for example `<name>_2pct.bam`), and FRACTION is 0.0025, 0.005, 0.01 or 0.02 for the labels `025pct`, `05pct`, `1pct` and `2pct`. 80 lines.

```bash
mkdir -p "$WORKDIR/bams_founder_Graph"
cd "$WORKDIR"

cp "$SRC_BAMS"/*.bam bams_founder_Graph/

sbatch --array=1-80%40 "$SUBSAMPLE_BATCH" subsample_parameters_founder_Graph.txt

mkdir -p bams_subsampled_founder_Graph && mv ./*.bam bams_subsampled_founder_Graph/
```

## 2. Build the workflow configuration

Uses the GRCm38 index paths.

`construct_mapping_accuracy_configs.py` reads one line per subsampled BAM from `Mapping_Accuracy_SnakeMake_Parameters_founder_Graph.txt`, tab-separated:
`BAM  RG1  PAF1  RG2  PAF2`
BAM is a file in `bams_subsampled_founder_Graph/` named `<A>-<B>_...`; RG1 is `<A>-lib1` and PAF1 is `Genome_Alignments/<A>_alignTo_GRCm38.paf.rfx`, and RG2 and PAF2 are the same for `<B>`. 80 lines.

```bash
cd "$WORKDIR"

python3 "$CONFIG_PY" Mapping_Accuracy_SnakeMake_Parameters_founder_Graph.txt
```

## 3. Run and combine

```bash
cd "$WORKDIR"

sbatch --array=1-80%20 "$ACCURACY_BATCH" \
  Mapping_Accuracy_SnakeMake_Parameters_founder_Graph.txt

mkdir -p Workflow_directories_founder_Graph
mv CC*pct Workflow_directories_founder_Graph/
```

Combine the accuracy tables as in `Calculate_mapping_accuracy.md`
step 6, pointing the loop at `Workflow_directories_founder_Graph/`.

Visualized in `Calculate_mapping_accuracy_Pan.Rmd`.
