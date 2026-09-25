# Lift the ENCODE cCRE annotation onto mT2T

Lifts the ENCODE mm10 candidate cis-regulatory element annotation onto the
Yu mT2T assembly, so regulatory analyses can be done in the same coordinate
system as the rest of the functional work.

Produces the annotation used by `Intersect_Variants_with_cCREs.md` and the
browser tracks.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `MT2T_FA` | mT2T assembly, liftover target |
| `GRCM38_FA` | GRCm38 assembly, liftover source |
| `CCRE_BED` | ENCODE mm10 cCRE annotation |
| `CHROM_SIZES` | mT2T chromosome sizes |
| `MM2_BATCH` | `run_Batch_minimap2_alignment__asm10_forLiftover.sh` |
| `RFX_INDEX_BATCH` | `run_Batch_refract_build-liftover-index.sh` |
| `REFRACT` | the `refract` binary |

```bash
WORKDIR=/path/to/Annotate_Yu_T2T_with_cCREs
MT2T_FA=/path/to/renamed_mhaESC_v1.1_with_mT2T-Y_v1.0.250617.fasta
GRCM38_FA=/path/to/GRCm38.p6.renamed.filtered.fa
CCRE_BED=/path/to/mm10-cCREs.All.bed
CHROM_SIZES=/path/to/mT2T-Y.chrom.sizes
MM2_BATCH=/path/to/run_Batch_minimap2_alignment__asm10_forLiftover.sh
RFX_INDEX_BATCH="../../../Alignments and Metrics/alignment-benchmarking/mapping-accuracy/run_Batch_refract_build-liftover-index.sh"
REFRACT=/path/to/refract
```

## Outputs

| File | Use |
|---|---|
| `mm10-cCREs.All.YuT2T.annotated.bed` | lifted cCREs with their original annotation columns |
| `*.rgbpeak.sorted.bed.gz` + `.tbi`, `.bb` | browser tracks, coloured by cCRE class |

## 1. Align GRCm38 to mT2T

`run_Batch_minimap2_alignment__asm10_forLiftover.sh` reads one line per alignment from `align_params.txt`, tab-separated:
`ReferenceFasta  QueryFasta  OutputPAF`
Here the reference is `$MT2T_FA`, the query `$GRCM38_FA`, and the output
`GRCm38_alignTo_mT2T.paf`. 1 line.

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Resources used: 72 GB, single task
sbatch --mem=72G --array=1 "$MM2_BATCH" align_params.txt
```

## 2. Build the refract liftover index

`run_Batch_refract_build-liftover-index.sh` reads one line per alignment from `refract_index_params.txt`, tab-separated:
`PAF  INDEX`
Here the PAF is `GRCm38_alignTo_mT2T.paf` and the index
`GRCm38_alignTo_mT2T.paf.rfx`. 1 line.

```bash
cd "$WORKDIR"

sbatch --array=1 "$RFX_INDEX_BATCH" refract_index_params.txt
```

## 3. Lift the cCREs

```bash
cd "$WORKDIR"

ln -s "$CCRE_BED" .

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval "$(spack load --sh gcc@11.2.0)"

"$REFRACT" liftover \
  --index GRCm38_alignTo_mT2T.paf.rfx \
  -q 5 \
  -l 50000 \
  -d 1 \
  mm10-cCREs.All.bed \
  > mm10-cCREs.All.bed.refract
```

| Flag | Meaning |
|---|---|
| `-q 5` | minimum mapping quality of the supporting alignment |
| `-l 50000` | maximum length of an interval to attempt |
| `-d 1` | maximum allowed distance/deviation |

## 4. Reattach the annotation columns

`refract` emits lifted coordinates and a name field built from the source
interval, but drops the remaining annotation columns. They are joined back by
matching that name against a `chrom_start_end` key from the original BED;
intervals that failed to lift get `NA`.

```bash
cd "$WORKDIR"

awk 'BEGIN{FS=OFS="\t"}
NR==FNR{
    key = $1"_"$2"_"$3
    ann = $4
    for(i=5; i<=NF; i++) ann = ann OFS $i
    annotations[key] = ann
    next
}
{
    if($4 in annotations) {
        print $0, annotations[$4]
    } else {
        print $0, "NA", "NA", "NA"
    }
}' mm10-cCREs.All.bed mm10-cCREs.All.bed.refract \
> mm10-cCREs.All.YuT2T.annotated.bed
```

Check how much failed to lift, overall and by cCRE class:

```bash
cd "$WORKDIR"

awk 'BEGIN{FS=OFS="\t"}
{
    total++
    any_na = 0
    for(i=1; i<=NF; i++) { if($i == "NA") { any_na = 1; break } }
    class = $NF
    if(any_na) total_any_na++
    if($NF == "NA") total_lastfield_na++
    class_total[class]++
    if(any_na) class_any_na[class]++
    if($NF == "NA") class_lastfield_na[class]++
}
END{
    print "OVERALL"
    print "total_lines", total
    print "lines_with_any_NA", total_any_na + 0
    print "lines_with_last_field_NA", total_lastfield_na + 0
    print ""
    print "BY_cCRE_CLASS"
    print "class", "total_lines", "lines_with_any_NA", "lines_with_last_field_NA"
    for(c in class_total) {
        print c, class_total[c], class_any_na[c] + 0, class_lastfield_na[c] + 0
    }
}' mm10-cCREs.All.YuT2T.annotated.bed | column -t
```

## 5. Build browser tracks

Colours follow the ENCODE cCRE class scheme.

| Class | RGB |
|---|---|
| PLS | `227,66,0` |
| PLS,CTCF-bound | `184,52,0` |
| pELS | `236,172,29` |
| pELS,CTCF-bound | `200,145,22` |
| dELS | `242,208,41` |
| dELS,CTCF-bound | `204,176,34` |
| CA-H3K4me3,CTCF-bound | `239,173,167` |
| CA-CTCF,CTCF-bound | `97,172,239` |
| TF | `169,55,222` |
| TF,CTCF-bound | `132,43,173` |
| anything else | `128,128,128` |

```bash
cd "$WORKDIR"

awk 'BEGIN{OFS="\t"}
{
  color = "128,128,128"
  if      ($9 == "PLS")                    color = "227,66,0"
  else if ($9 == "PLS,CTCF-bound")         color = "184,52,0"
  else if ($9 == "pELS")                   color = "236,172,29"
  else if ($9 == "pELS,CTCF-bound")        color = "200,145,22"
  else if ($9 == "dELS")                   color = "242,208,41"
  else if ($9 == "dELS,CTCF-bound")        color = "204,176,34"
  else if ($9 == "CA-H3K4me3,CTCF-bound")  color = "239,173,167"
  else if ($9 == "CA-CTCF,CTCF-bound")     color = "97,172,239"
  else if ($9 == "TF")                     color = "169,55,222"
  else if ($9 == "TF,CTCF-bound")          color = "132,43,173"
  print $1, $2, $3, $8, 1000, ".", $2, $3, color
}' mm10-cCREs.All.YuT2T.annotated.bed \
| sort -k1,1 -k2,2n \
> mm10-cCREs.All.YuT2T.annotated.rgbpeak.sorted.bed

eval $( spack load --sh samtools/5xvuvgk )   # samtools, version not recorded (build hash 5xvuvgk)
bgzip -@ 8 -f -c mm10-cCREs.All.YuT2T.annotated.rgbpeak.sorted.bed \
  > mm10-cCREs.All.YuT2T.annotated.rgbpeak.sorted.bed.gz
tabix -f -p bed mm10-cCREs.All.YuT2T.annotated.rgbpeak.sorted.bed.gz

eval $( spack load --sh kentutils@302.1 )
bedToBigBed \
  mm10-cCREs.All.YuT2T.annotated.rgbpeak.sorted.bed \
  "$CHROM_SIZES" \
  mm10-cCREs.All.YuT2T.annotated.rgbpeak.sorted.bb
```
