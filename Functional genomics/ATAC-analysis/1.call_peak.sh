#!/bin/bash

# ----------------------------
# 1. Setup and Variables
# ----------------------------

set -e  # Stop on error

SAMPLES=('SAMPLE1' 'SAMPLE2')  # Replace with actual sample names
T=24

script="/path/to/scripts"
OUT="/path/to/output"
pangenome="/path/to/pangenome"

genome="/path/to/genome"
encode="/path/to/encode"
tss_bed="/path/to/tss.bed"
genome_sizes="/path/to/genome.sizes"
blacklist="/path/to/blacklist.bed"

gbz="./CC.full.multi.gbz"
dist="./CC.full.dist"
min="./CC.full.min"
gfa="${pangenome}/CC.full.gfa"

# ----------------------------
# 2. Function Definitions
# ----------------------------

call_macs2() {
    local tagalign="$1"
    local name="$2"
    local outdir="$3"
    macs2 callpeak -t "$tagalign" -f BEDPE -n "$name" -g mm \
        -q 0.01 --nomodel --shift -75 --extsize 150 -B --SPMR \
        --call-summits --keep-dup all --outdir "$outdir"
}

filter_peaks() {
    local input_peak="$1"
    local blacklist="$2"
    local output_peak="$3"
    bedtools intersect -v -a "$input_peak" -b "$blacklist" | \
        grep -P '^chr[\dXY]+\t' > "$output_peak"
}

# ----------------------------
# 3. Peak Calling and Processing
# ----------------------------

cd "${OUT}"

for NAME in "${SAMPLES[@]}"; do
    echo "[INFO] Processing sample: ${NAME}"
    samtools view -@ 64 -b -f 0x2 "${NAME}_mm10.bam" > "${NAME}_mm10.proper_paired.bam"
    samtools sort -@ 64 -o "${NAME}_mm10.sorted.bam" "${NAME}_mm10.proper_paired.bam"
    samtools sort -n -@ 64 -o "${NAME}_mm10_genome_srt.bam" "${NAME}_mm10.sorted.bam"

    bedtools bamtobed -bedpe -mate1 -i "${NAME}_mm10_genome_srt.bam" | \
    awk 'BEGIN { OFS="\t" } { printf "%s\t%s\t%s\tN\t1000\t%s\n%s\t%s\t%s\tN\t1000\t%s\n", $1,$2,$3,$9,$4,$5,$6,$10 }' | gzip -nc > "${NAME}_mm10.bedpe.gz"

    zcat "${NAME}_mm10.bedpe.gz" | \
    awk 'BEGIN { OFS="\t" } { if ($6 == "+") { $2 += 4 } else if ($6 == "-") { $3 -= 5 } print }' | gzip -nc > "${NAME}_mm10.tn5.tagAlign.gz"

    zcat "${NAME}_mm10.tn5.tagAlign.gz" | \
    awk 'BEGIN{OFS="\t"} { if($2 < $3) print }' | gzip -nc > "${NAME}_mm10.tn5.fix.tagAlign.gz"

    call_macs2 "${NAME}_mm10.tn5.fix.tagAlign.gz" "${NAME}_mm10" "${NAME}_mm10"
done

# ----------------------------
# 5. Pooled and Pseudo-replicate Analysis
# ----------------------------

zcat -f "${SAMPLES[@]/%/_mm10.tn5.fix.tagAlign.gz}" | gzip -nc > "F_pooled.tn5.fix.tagAlign.gz"
call_macs2 "F_pooled.tn5.fix.tagAlign.gz" "F_pooled" "F_pooled"
awk -F '#' '{print $3}' "F_pooled/F_pooled_peaks.narrowPeak" > "F_pooled/F_pooled_peaks.narrowPeak1"
filter_peaks "F_pooled/F_pooled_peaks.narrowPeak1" "$blacklist" "F_pooled_peaks.filt.narrowPeak"

for SAMPLE in "${SAMPLES[@]}"; do
    total_lines=$(zcat "${SAMPLE}_mm10.tn5.fix.tagAlign.gz" | wc -l)
    lines_per_file=$(((total_lines / 2) + 1))
    zcat "${SAMPLE}_mm10.tn5.fix.tagAlign.gz" | shuf | split -d -l "$lines_per_file" - "${SAMPLE}_pseudo"
done

cat "${SAMPLES[0]}_pseudo00" "${SAMPLES[1]}_pseudo00" | bgzip -c > "F_00.tn5.fix.tagAlign.gz"
cat "${SAMPLES[0]}_pseudo01" "${SAMPLES[1]}_pseudo01" | bgzip -c > "F_01.tn5.fix.tagAlign.gz"

call_macs2 "F_00.tn5.fix.tagAlign.gz" "F_00" "F_00"
call_macs2 "F_01.tn5.fix.tagAlign.gz" "F_01" "F_01"

# ----------------------------
# 6. Final Peak List Generation
# ----------------------------

for SAMPLE in "${SAMPLES[@]}"; do
    awk -F '#' '{print $3}' "${SAMPLE}_mm10/${SAMPLE}_mm10_peaks.narrowPeak" > "${SAMPLE}_mm10/${SAMPLE}_mm10_peaks.narrowPeak1"
    filter_peaks "${SAMPLE}_mm10/${SAMPLE}_mm10_peaks.narrowPeak1" "$blacklist" "${SAMPLE}_mm10_peaks.filt.narrowPeak"
done

for PSEUDO in "F_00" "F_01"; do
    awk -F '#' '{print $3}' "${PSEUDO}/${PSEUDO}_peaks.narrowPeak" > "${PSEUDO}/${PSEUDO}_peaks.narrowPeak1"
    filter_peaks "${PSEUDO}/${PSEUDO}_peaks.narrowPeak1" "$blacklist" "${PSEUDO}_peaks.filt.narrowPeak"
done

duplicate_peaks="F_duplicates.peaks"
pseudos_peaks="F_pseudos.peaks"
naive_peak_list="F_naivePeakList"
summit_list="F_naiveSummitList.bed"

intersectBed -wo -a "F_pooled_peaks.filt.narrowPeak" -b "${SAMPLES[0]}_mm10_peaks.filt.narrowPeak" | \
awk 'BEGIN { FS=OFS="\t" } { s1=$3-$2; s2=$13-$12; if (($21/s1>=0.5)||($21/s2>=0.5)) print }' | cut -f1-10 | \
intersectBed -wo -a stdin -b "${SAMPLES[1]}_mm10_peaks.filt.narrowPeak" | \
awk 'BEGIN { FS=OFS="\t" } { s1=$3-$2; s2=$13-$12; if (($21/s1>=0.5)||($21/s2>=0.5)) print }' | cut -f1-10 | \
sort -k1,1 -k2,2n | uniq > "$duplicate_peaks"

intersectBed -wo -a "F_pooled_peaks.filt.narrowPeak" -b "F_00_peaks.filt.narrowPeak" | \
awk 'BEGIN { FS=OFS="\t" } { s1=$3-$2; s2=$13-$12; if (($21/s1>=0.5)||($21/s2>=0.5)) print }' | cut -f1-10 | \
sort -k1,1 -k2,2n | uniq | \
intersectBed -wo -a stdin -b "F_01_peaks.filt.narrowPeak" | \
awk 'BEGIN { FS=OFS="\t" } { s1=$3-$2; s2=$13-$12; if (($21/s1>=0.5)||($21/s2>=0.5)) print }' | cut -f1-10 | \
sort -k1,1 -k2,2n | uniq > "$pseudos_peaks"


# ----------------------------
# 8. Combine Final Peak Lists
# ----------------------------

cat "$duplicate_peaks" "$pseudos_peaks" | \
sort -k1,1 -k2,2n | uniq | \
awk 'BEGIN { OFS="\t" } { if ($5 > 1000) $5 = 1000; print }' | \
grep -P 'chr[0-9XY]+' > "$naive_peak_list"

join -1 1 -2 4 <(cut -f4 "$naive_peak_list" | sort) \
     <(sort -k4,4 "F_pooled/F_pooled_summits.bed") -t $'\t' | \
awk 'BEGIN { FS=OFS="\t" } { print $2, $3, $4, $1, $5 }' | \
sort -k1,1 -k2,2n > "$summit_list"