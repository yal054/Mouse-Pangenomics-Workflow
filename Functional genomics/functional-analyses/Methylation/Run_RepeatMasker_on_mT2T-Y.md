# RepeatMasker annotation of the mT2T-Y assembly

Annotates repeats in the C57BL/6J mT2T assembly carrying mT2T-Y
(`renamed_mhaESC_v1.1_with_mT2T-Y_v1.0.250617`).

Supplies the repeat track for the browser views.

## Requirements

RepeatMasker must be installed with the Mammalian Dfam database. The
cluster's spack-provided RepeatMasker 4.1.5 ships only the base Dfam database,
which is not sufficient for mouse: a run against it completes but under-annotates.
A separate installation with the full Mammalian partition was used instead.

Use `-species house_mouse`, not `mm10`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `ASSEMBLY` | mT2T-Y assembly |
| `RM_BATCH` | `run_Batch_RepeatMasker.sh`, pointed at a Dfam-complete install |

```bash
WORKDIR=/path/to/mT2T-Y_v1.0
ASSEMBLY=/path/to/renamed_mhaESC_v1.1_with_mT2T-Y_v1.0.250617.fasta
RM_BATCH=run_Batch_RepeatMasker.sh
```

## Outputs

`<assembly>.out` and `<assembly>.tbl`, the RepeatMasker annotation and its
summary table.

## 1. Run RepeatMasker

Submit as a batch job. An interactive run does not complete within a session
and is killed part-way.

`run_Batch_RepeatMasker.sh` reads one line per assembly from `rm_params.txt`, tab-separated:
`INPUTFASTA  SPECIES`
Here the assembly is `$ASSEMBLY` and the species `house_mouse`. 1 line.

```bash
cd "$WORKDIR"
# Resources used: 20 threads, submitted as a 1-element array
sbatch --array=1-1%1 "$RM_BATCH" rm_params.txt
```

## 2. Check the annotation

```bash
cd "$WORKDIR"
FA=$(basename "$ASSEMBLY")

# summary table
cat "$FA.tbl"

# hits per repeat class/family
awk 'NR>3 {count[$11]++} END {print "class_family\tn_hits"; for (k in count) print k"\t"count[k]}' "$FA.out"

# B1 SINE count, as a sanity check against expectation for mouse
awk '$11 ~ /^SINE/ && $10 ~ /^B1/' "$FA.out" | wc -l
```

## Downstream

The `.out` file is converted to bigBed for browser display as in
`Run_RepeatMasker_on_CAST_T2T.md` sections 4–7 (awk reshaping and autoSql
schema).
