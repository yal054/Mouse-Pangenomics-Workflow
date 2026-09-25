# Lift CAST methylation calls onto mT2T coordinates

Lifts the CAST/EiJ methylation call sets from CAST-T2T coordinates onto mT2T,
so that CAST-aligned and mT2T-aligned methylomes can be compared on one
coordinate system.

Produces the lifted CAST call sets used for the cross-reference comparison,
and feeds the browser views.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `MT2T_FA` | mT2T assembly, the liftover target |
| `CAST_FA` | CAST/EiJ T2T assembly, the liftover source |
| `BISMARK_CAST` | Bismark calls for CAST, aligned to CAST-T2T |
| `HSE_DIR` | methylGrapher HSE call sets in CAST coordinates |
| `MM2_BATCH` | `run_Batch_minimap2_alignment__asm10_forLiftover.sh` |
| `RFX_INDEX_BATCH` | `run_Batch_refract_build-liftover-index.sh` |
| `RFX_LIFT_BATCH` | `run_Batch_refract_liftover_with_index.sh` |

```bash
WORKDIR=/path/to/WGBS
MT2T_FA=/path/to/renamed_mhaESC_v1.1_with_mT2T-Y_v1.0.250617.fasta
CAST_FA=/path/to/GCA_964188545.1_CAST_EiJ_T2T_v1_genomic.renamed.filtered.fa
BISMARK_CAST=/path/to/Bismark_data/cast/merged_cast/track.cpg.methylc.gz
HSE_DIR=/path/to/methylGrapher_HSE
MM2_BATCH=/path/to/run_Batch_minimap2_alignment__asm10_forLiftover.sh
RFX_INDEX_BATCH="../../../Alignments and Metrics/alignment-benchmarking/mapping-accuracy/run_Batch_refract_build-liftover-index.sh"
RFX_LIFT_BATCH=run_Batch_refract_liftover_with_index.sh
```

## Outputs

`Liftover_Methylation_Calls/Liftover_Methylation_Calls_merged/*.mT2T_merged.methylC.gz`,
five call sets on mT2T coordinates, each retaining its pre-liftover
coordinates.

## 1. Align CAST-T2T to mT2T

`run_Batch_minimap2_alignment__asm10_forLiftover.sh` reads one line per alignment from `align_params.txt`, tab-separated:
`ReferenceFasta  QueryFasta  OutputPAF`
Here the reference is `$MT2T_FA`, the query `$CAST_FA`, and the output
`CAST_T2T_alignTo_mT2T.paf`. 1 line.

```bash
cd "$WORKDIR"

# Resources used: 72 GB, single task
sbatch --mem=72G --array=1 "$MM2_BATCH" align_params.txt

mkdir -p Genome_Alignments_T2T
mv ./*.paf Genome_Alignments_T2T/
```

## 2. Build the refract liftover index

`run_Batch_refract_build-liftover-index.sh` reads one line per alignment from `refract_index_params.txt`, tab-separated:
`PAF  INDEX`
Here the PAF is `CAST_T2T_alignTo_mT2T.paf` and the index
`CAST_T2T_alignTo_mT2T.paf.rfx`. 1 line.

```bash
cd "$WORKDIR/Genome_Alignments_T2T"

sbatch --array=1 "$RFX_INDEX_BATCH" refract_index_params.txt
```

## 3. Stage the five call sets

Named on linking so the outputs are self-describing.

```bash
mkdir -p "$WORKDIR/Liftover_Methylation_Calls"
cd "$WORKDIR/Liftover_Methylation_Calls"

ln -s "$BISMARK_CAST"                                        Bismark_merged_cast_methylc.gz
ln -s "$HSE_DIR/mg.merged_cast.mapq0.hse2cast.methyl.gz"      mg.merged_cast.mapq0.hse2cast.methyl.gz
ln -s "$HSE_DIR/mg.merged_cast.mapq10.hse2cast.methyl.gz"     mg.merged_cast.mapq10.hse2cast.methyl.gz
ln -s "$HSE_DIR/mg_full.merged_cast.mapq0.hse2cast.methyl.gz" mg_full.merged_cast.mapq0.hse2cast.methyl.gz
ln -s "$HSE_DIR/mg_full.merged_cast.mapq10.hse2cast.methyl.gz" mg_full.merged_cast.mapq10.hse2cast.methyl.gz

# refract reads uncompressed input
for f in *.gz; do
    echo "Decompressing $f"
    pigz -dc "$f" > "${f%.gz}"
done
```

## 4. Lift each call set

`run_Batch_refract_liftover_with_index.sh` reads one line per call set from `refract_liftover_params.txt`, tab-separated:
`INDEX  INPUT  OUTPUT`
`INDEX` is `$WORKDIR/Genome_Alignments_T2T/CAST_T2T_alignTo_mT2T.paf.rfx` from
step 2, `INPUT` is an uncompressed call set from step 3, and `OUTPUT` is the
input name with `.refract` appended. 5 lines.

```bash
cd "$WORKDIR/Liftover_Methylation_Calls"

# Resources used: 16 GB per task, 5 tasks
sbatch --mem=16G --array=1-5%5 "$RFX_LIFT_BATCH" refract_liftover_params.txt
```

## 5. Rejoin lifted coordinates with the methylation values

`refract` emits only the lifted coordinates. Each `.refract` file is in the same
row order as its input, so they are pasted back together column-wise.

Output layout:

| Columns | Contents |
|---|---|
| 1–3 | mT2T coordinates (from `.refract`) |
| 4–7 | methylation values (from the original call set) |
| 8–10 | pre-liftover CAST coordinates |
| 11–12 | graph coordinates, where the source had them |

The two input shapes are distinguished by field count: 13 for Bismark, 15 or
more for the methylGrapher sets that carry graph coordinates.

```bash
cd "$WORKDIR/Liftover_Methylation_Calls"

for f in Bismark_merged_cast_methylc mg*.methyl; do
    echo "Merging $f"
    paste "${f}.refract" "$f" \
    | awk 'BEGIN{OFS="\t"}
      NF==13 {print $1,$2,$3,$10,$11,$12,$13,$7,$8,$9}
      NF>=15 {print $1,$2,$3,$10,$11,$12,$13,$7,$8,$9,$14,$15}' \
    > "${f}.mT2T_merged.methylC"
done
```

## 6. Compress and collect

```bash
cd "$WORKDIR/Liftover_Methylation_Calls"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools@1.13/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)

for f in *.mT2T_merged.methylC; do
    echo "Compressing $f"
    bgzip -@ 8 -c "$f" > "${f%.methylC}.methylC.gz"
done

mkdir -p Liftover_Methylation_Calls_merged
mv ./*.methylC.gz Liftover_Methylation_Calls_merged/
rm -f ./*.mT2T_merged.methylC
```

The uncompressed inputs, the symlinks and the `.refract` intermediates can be
removed once the merged sets exist.
