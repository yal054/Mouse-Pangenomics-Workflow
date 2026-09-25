# Genome alignments for read liftover: mT2T

Aligns each of the 40 CC RI simulation assemblies to the C57BL/6J mT2T assembly,
producing the PAF files used to lift simulated read positions onto it.

The mT2T counterpart of `Prepare_genome_alignments.md`. Prerequisite for
`Calculate_mapping_accuracy_mT2T_BWA.md`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `ASSEMBLY_DIR` | the 40 CC simulation assemblies, staged as in the GRCm38 protocol |
| `REFERENCE` | mT2T reference, the build used for alignment |
| `MM2_BATCH` | `run_Batch_minimap2_alignment__asm10_forLiftover.sh` |

```bash
WORKDIR=/path/to/Mapping_Accuracy_Analysis
ASSEMBLY_DIR="$WORKDIR/CC-sim-assemblies"
REFERENCE=/path/to/renamed_mhaESC_v1.1_with_mT2T-Y_v1.0.250617.fasta
MM2_BATCH=/path/to/run_Batch_minimap2_alignment__asm10_forLiftover.sh
```

> The reference must be the same file the reads were aligned against.

## Outputs

`Genome_Alignments_T2T/<line>_alignTo_mT2T.paf`, one per RI line.

## 1. Align each assembly to the reference

Assembly staging is shared with the GRCm38 protocol; run that first, or stage
`ASSEMBLY_DIR` the same way.

`run_Batch_minimap2_alignment__asm10_forLiftover.sh` reads one line per assembly from `alignment_manifest_T2T.txt`, tab-separated:
`ReferenceFasta  QueryFasta  OutputPAF`
ReferenceFasta is `$REFERENCE` on every line, QueryFasta is an assembly `.fasta` in `ASSEMBLY_DIR`, and OutputPAF is `<line>_alignTo_mT2T.paf`. 40 lines.

```bash
cd "$WORKDIR"

# Resources used: 72 GB per task, 40 tasks, 10 concurrent
sbatch --mem=72G --array=1-40%10 "$MM2_BATCH" alignment_manifest_T2T.txt
```

## 2. Collect the alignments

```bash
cd "$WORKDIR"
mkdir -p Genome_Alignments_T2T
mv ./*.paf Genome_Alignments_T2T/
```
