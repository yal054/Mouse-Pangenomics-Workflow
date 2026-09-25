# RepeatMasker annotation of the CAST/EiJ T2T assembly

Annotates repeats in the CAST/EiJ T2T assembly (GCA_964188545.1) and converts
the output to bigBed for genome-browser display.

Supplies the repeat annotation for the TE-subfamily context and the repeat
track in the browser views.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `ASSEMBLY` | CAST/EiJ T2T assembly, renamed and filtered |
| `SPECIES` | RepeatMasker species; `house_mouse` was used |
| `RM_BATCH` | `run_Batch_RepeatMasker.sh` |

```bash
WORKDIR=/path/to/CAST_EiJ_T2T
ASSEMBLY=/path/to/GCA_964188545.1_CAST_EiJ_T2T_v1_genomic.renamed.filtered.fa
SPECIES=house_mouse
RM_BATCH=run_Batch_RepeatMasker.sh
```

The assembly was produced upstream.

> RepeatMasker is run from a local install rather than the spack one, with
> RMBlast and TRF placed on `PATH`. The spack build lacks the Mammalian Dfam
> database; see `Run_RepeatMasker_on_mT2T-Y.md`. `run_Batch_RepeatMasker.sh`
> carries the exact paths.

## Outputs

`CAST_EiJ_T2T.rmsk16.bb`, RepeatMasker annotation as a 16-field bigBed,
alongside the raw `.out`/`.tbl` RepeatMasker output.

## 1. Stage the assembly

```bash
mkdir -p "$WORKDIR"
cp "$ASSEMBLY" "$WORKDIR/"
```

## 2. Run RepeatMasker

`run_Batch_RepeatMasker.sh` reads one line per assembly from `rm_params.txt`, tab-separated:
`INPUTFASTA  SPECIES`
Here the assembly is the copy staged in `$WORKDIR` in step 1 and the species
`$SPECIES` (`house_mouse`). 1 line.

```bash
cd "$WORKDIR"
# Resources used: single task, submitted as a 1-element array
sbatch --array=1-1%1 "$RM_BATCH" rm_params.txt
```

## 3. Check the annotation

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

## 4. Convert the RepeatMasker output to BED

Reshapes the `.out` table into the 16-field UCSC `rmsk` layout: coordinates to
0-based half-open, divergence values to parts per thousand, parenthesised
remainders to signed values, and the class/family field split on `/`. Repeat
consensus coordinates are oriented by strand.

```bash
cd "$WORKDIR"
FA=$(basename "$ASSEMBLY")

awk '
BEGIN { OFS="\t" }

NR <= 3 { next }
NF < 15 { next }

function unparen(x) {
  gsub(/[()]/, "", x)
  return x
}

function round10(x) {
  return int((x * 10) + 0.5)
}

{
  chrom      = $5
  chromStart = $6 - 1
  chromEnd   = $7
  name       = $10
  score      = 0

  strand = ($9 == "C" ? "-" : "+")

  swScore  = $1
  milliDiv = round10($2)
  milliDel = round10($3)
  milliIns = round10($4)

  genoLeft = -unparen($8)

  repNameRaw = $11
  repClass = repNameRaw
  repFamily = repNameRaw
  slashPos = index(repNameRaw, "/")
  if (slashPos > 0) {
    repClass = substr(repNameRaw, 1, slashPos - 1)
    repFamily = substr(repNameRaw, slashPos + 1)
  }

  repBegin = $12
  repEnd   = $13
  repLeftRaw = unparen($14)

  if (strand == "+") {
    repStart = repBegin - 1
    repLeft  = -repLeftRaw
  } else {
    repStart = -repLeftRaw
    repLeft  = repBegin - 1
  }

  print chrom, chromStart, chromEnd, name, score, strand,
        swScore, milliDiv, milliDel, milliIns, genoLeft,
        repClass, repFamily, repStart, repEnd, repLeft
}
' "$FA.out" \
| sort -k1,1V -k2,2n \
> CAST_EiJ_T2T.rmsk16.bed
```

## 5. Write the autoSql schema

```bash
cd "$WORKDIR"

cat > rmsk16.as <<'EOF'
table rmsk16
"RepeatMasker annotations"
(
string chrom;      "Reference sequence chromosome or scaffold"
uint chromStart;   "Start position in chromosome"
uint chromEnd;     "End position in chromosome"
string name;       "Repeat name"
uint score;        "Score"
char[1] strand;    "+ or -"
uint swScore;      "Smith-Waterman score"
uint milliDiv;     "Base mismatches in parts per thousand"
uint milliDel;     "Bases deleted in parts per thousand"
uint milliIns;     "Bases inserted in parts per thousand"
int genoLeft;      "Bases left in genomic sequence"
string repClass;   "Repeat class"
string repFamily;  "Repeat family"
int repStart;      "Start in repeat consensus"
int repEnd;        "End in repeat consensus"
int repLeft;       "Bases left in repeat consensus"
)
EOF
```

## 6. Build chromosome sizes

```bash
cd "$WORKDIR"
FA=$(basename "$ASSEMBLY")

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)
samtools faidx "$FA"
cut -f1,2 "$FA.fai" > CAST_EiJ_T2T.chrom.sizes
```

## 7. Convert to bigBed and verify

```bash
cd "$WORKDIR"

eval $( spack load --sh kentutils@302.1 )

bedToBigBed \
  -type=bed6+10 \
  -as=rmsk16.as \
  CAST_EiJ_T2T.rmsk16.bed \
  CAST_EiJ_T2T.chrom.sizes \
  CAST_EiJ_T2T.rmsk16.bb

bigBedToBed CAST_EiJ_T2T.rmsk16.bb stdout | head
```
