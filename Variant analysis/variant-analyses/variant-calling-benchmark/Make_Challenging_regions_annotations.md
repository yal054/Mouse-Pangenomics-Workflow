# Challenging-region annotations for mm10

Builds the repeat, tandem-repeat and segmental-duplication annotation used to
stratify the variant-calling benchmark into easy and challenging regions.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | output directory |
| `UCSC_URL` | UCSC `goldenPath` database directory for mm10 |

```bash
WORKDIR=/path/to/Challenging_regions
UCSC_URL=https://hgdownload.soe.ucsc.edu/goldenPath/mm10/database
```

## Outputs

`mm10.repeat_trf_segdup.challenge_union.bed`, the merged challenging-region
union, plus the three per-source BED files it is built from.

## 1. Retrieve the UCSC tables

The `.sql` files carry the column definitions for each table and are fetched
alongside the data so the field offsets below can be checked.

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

for t in rmsk simpleRepeat genomicSuperDups; do
    wget "$UCSC_URL/${t}.txt.gz"
    wget "$UCSC_URL/${t}.sql"
done
```

## 2. Convert each table to BED

RepeatMasker is restricted to the three classes that make variant calling hard:
low complexity, simple repeats and satellites. The other two tables are taken
whole.

```bash
cd "$WORKDIR"

gzip -cd rmsk.txt.gz \
  | awk 'BEGIN{OFS="\t"} $12=="Low_complexity" || $12=="Simple_repeat" || $12=="Satellite" {print $6, $7, $8, $11, $2, $10, $12, $13}' \
  > mm10.rmsk.Low_complexity.Simple_repeat.Satellite.bed

gzip -cd simpleRepeat.txt.gz \
  | awk 'BEGIN{OFS="\t"} {print $2, $3, $4, $5, $11, ".", $6, $7, $8, $9, $10}' \
  > mm10.simpleRepeat.bed

gzip -cd genomicSuperDups.txt.gz \
  | awk 'BEGIN{OFS="\t"} {print $2, $3, $4, $5, $6, $7}' \
  > mm10.genomicSuperDups.bed
```

## 3. Merge into a single challenging-region union

```bash
cd "$WORKDIR"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh bedtools2@2.30.0/f3mnrck )   # bedtools2 2.30.0 (build hash f3mnrck)

cat \
  mm10.rmsk.Low_complexity.Simple_repeat.Satellite.bed \
  mm10.simpleRepeat.bed \
  mm10.genomicSuperDups.bed \
  | cut -f1-3 \
  | sort -k1,1 -k2,2n \
  | bedtools merge -i - \
  > mm10.repeat_trf_segdup.challenge_union.bed
```

## 4. Check the result

```bash
cd "$WORKDIR"

wc -l ./*.bed
awk 'BEGIN{OFS="\t"} {sum += $3 - $2} END{print "bp", sum, "Mb", sum/1000000}' \
  mm10.repeat_trf_segdup.challenge_union.bed
```
