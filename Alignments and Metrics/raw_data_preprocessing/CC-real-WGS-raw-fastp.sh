#!/usr/bin/env bash
set -euo pipefail

SAMPLES_FILE="${1:-samples.txt}"

OUTDIR="fastp-processed"
LOGDIR="${OUTDIR}/logs"

mkdir -p "$OUTDIR" "$LOGDIR"

submitted=0
missing=0

while IFS= read -r sample || [[ -n "$sample" ]]; do
  sample="${sample//$'\r'/}"
  sample="${sample%%#*}"
  sample="$(echo "$sample" | tr -d '[:space:]')"
  [[ -z "$sample" ]] && continue

  mapfile -t r1s < <( ls *"-${sample}-"*.R1.fastq.gz 2>/dev/null | sort -V || true )

  if (( ${#r1s[@]} == 0 )); then
    echo "WARN: no R1 files found for sample ${sample}" >&2
    missing=$((missing+1))
    continue
  fi

  for r1 in "${r1s[@]}"; do
    base="${r1%.R1.fastq.gz}"
    r2="${base}.R2.fastq.gz"

    if [[ ! -f "$r2" ]]; then
      echo "WARN: missing R2 for ${base} (expected: ${r2})" >&2
      missing=$((missing+1))
      continue
    fi

    label="$(basename "$base")"

    json="${OUTDIR}/fastp.${label}.json"
    html="${OUTDIR}/fastp.${label}.html"
    out1="${OUTDIR}/QCd-${label}_R1.fastq"
    out2="${OUTDIR}/QCd-${label}_R2.fastq"

     "fastp \
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
        --out2 ${out2}"

    submitted=$((submitted+1))
  done
done < "$SAMPLES_FILE"

echo "Done. Submitted ${submitted} jobs. Missing/partial pairs: ${missing}" >&2
