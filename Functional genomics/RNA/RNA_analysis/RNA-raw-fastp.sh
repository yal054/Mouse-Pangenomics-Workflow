OUTDIR="fastp-processed"
LOGDIR="logs"

THREADS=16

for r1 in *_R1_001.fastq.gz; do
    r2="${r1/_R1_001.fastq.gz/_R2_001.fastq.gz}"
    label="${r1%_R1_001.fastq.gz}"

    json="${OUTDIR}/fastp.${label}.json"
    html="${OUTDIR}/fastp.${label}.html"
    out1="${OUTDIR}/QCd-${label}_R1.fastq"
    out2="${OUTDIR}/QCd-${label}_R2.fastq"

      fastp \
        --thread ${THREADS} \
        --verbose \
        --dedup \
        --overrepresentation_analysis \
        --detect_adapter_for_pe \
        --in1 ${r1} \
        --in2 ${r2} \
        --json ${json} \
        --html ${html} \
        --out1 ${out1} \
        --out2 ${out2}
done
