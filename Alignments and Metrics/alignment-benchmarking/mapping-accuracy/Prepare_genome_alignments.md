# Genome alignments for read liftover: GRCm38

Aligns each of the 40 CC RI simulation assemblies to GRCm38, producing the PAF
files used to lift simulated read positions from their source assembly onto the
reference being benchmarked.

Prerequisite for `Calculate_mapping_accuracy.md`.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `ASSEMBLY_DIR` | the 40 CC simulation assemblies, one `.fasta` each |
| `REFERENCE` | GRCm38 reference, the build used for alignment |
| `MM2_BATCH` | `run_Batch_minimap2_alignment__asm10_forLiftover.sh` |

```bash
WORKDIR=/path/to/Mapping_Accuracy_Analysis
ASSEMBLY_DIR="$WORKDIR/CC-sim-assemblies"
REFERENCE=/path/to/GRCm38.p6.renamed.filtered.fa
MM2_BATCH=/path/to/run_Batch_minimap2_alignment__asm10_forLiftover.sh
```

> The reference must be the same file the reads were aligned against. A
> different GRCm38 build will not lift consistently. Both the assemblies and the
> reference were produced upstream.

## Outputs

`Genome_Alignments/<line>_alignTo_GRCm38.paf`, one per RI line.

## 1. Stage the assemblies

The delivered assembly tree carries duplicate `.fasta` files in per-line
subdirectories plus a helper script; keep only the top-level assemblies.

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

rm -f  "$ASSEMBLY_DIR"/CC0*/r*.fasta
rm -rf "$ASSEMBLY_DIR"/CC0*/
rm -f  "$ASSEMBLY_DIR"/*.sh
```

## 2. Align each assembly to the reference

`run_Batch_minimap2_alignment__asm10_forLiftover.sh` reads one line per assembly from `alignment_manifest.txt`, tab-separated:
`ReferenceFasta  QueryFasta  OutputPAF`
ReferenceFasta is `$REFERENCE` on every line, QueryFasta is an assembly `.fasta` in `ASSEMBLY_DIR`, and OutputPAF is `<line>_alignTo_GRCm38.paf`. 40 lines.

```bash
cd "$WORKDIR"

# Resources used: 128 GB per task, 40 tasks, 10 concurrent
sbatch --mem=128G --array=1-40%10 "$MM2_BATCH" alignment_manifest.txt
```

Alignment is `asm10`, appropriate for within-species assembly-to-reference
comparison, and emits PAF suitable for coordinate liftover.

## 3. Collect the alignments

```bash
cd "$WORKDIR"
mkdir -p Genome_Alignments
mv ./*.paf Genome_Alignments/
```

The assembly FASTA files are needed only for this step and can be removed once
the PAFs exist.
