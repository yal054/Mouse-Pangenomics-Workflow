#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

if [[ $# -ne 1 ]]; then
    echo "Usage: bash rg-and-merge-script.sh SAMPLE" >&2
    exit 1
fi

SAMPLE="$1"

############################
# user-tunable settings
############################

INPUT_DIR=""

# per-file BAMs after RG assignment
RG_ROOT=""

# final merged BAMs
MERGE_DIR=""

THREADS=16
PLATFORM="ILLUMINA"

# 0 = skip deeper consistency checks
# N > 0 = inspect first N alignments of each file to confirm same flowcell/lane
CHECK_N_READS=0

# 0 = skip outputs that already exist
# 1 = rebuild outputs
OVERWRITE=0

############################
# setup
############################

SAMPLE_RG_DIR="${RG_ROOT}/${SAMPLE}"
MANIFEST="${SAMPLE_RG_DIR}/${SAMPLE}.rg_manifest.tsv"
MERGED_BAM="${MERGE_DIR}/${SAMPLE}.merged.bam"

mkdir -p "$SAMPLE_RG_DIR" "$MERGE_DIR"

############################
# helpers
############################

get_first_readname() {
    local bam="$1"
    samtools view "$bam" | awk 'NR==1 { print $1; exit }'
}

get_first_readname() {
    local bam="$1"
    local readname rc

    # after awk prints first line, sends SIGPIPE signal to close pipe
    # samtools tries to write to a closed pipe and exits with code 141
    # set -o pipefail sets this as the return code for the whole line,
    # and set -e then immediately exits the script with that code
    # so temporarily unset it and handle the error code manually
    # annoying, but safer than leaving pipefail unset
    set +e
    readname=$(
        samtools view "$bam" | awk 'NR==1 { print $1; exit }'
    )
    rc=$?
    set -e

    [[ "$rc" -eq 0 || "$rc" -eq 141 ]] || return "$rc"
    [[ -n "$readname" ]] || {
        echo "ERROR: no alignments found in $bam" >&2
        return 1
    }

    printf '%s\n' "$readname"
}

check_readname_consistency() {
    local bam="$1"
    local expected_flowcell="$2"
    local expected_lane="$3"
    local n_reads="$4"

    samtools view "$bam" | awk -v n="$n_reads" -v fc="$expected_flowcell" -v lane="$expected_lane" -v file="$bam" '
        NR > n { exit }
        {
            split($1, a, ":")
            if (length(a) < 4) {
                printf("ERROR: malformed read name in %s at record %d: %s\n", file, NR, $1) > "/dev/stderr"
                exit 1
            }
            if (a[3] != fc || a[4] != lane) {
                printf("ERROR: inconsistent flowcell/lane in %s at record %d: %s\n", file, NR, $1) > "/dev/stderr"
                exit 1
            }
        }
    '
}

############################
# gather BAMs for sample
############################

mapfile -t BAMS < <(
    printf '%s\n' "${INPUT_DIR}"/*-"${SAMPLE}"-*.bam | sort
)

if (( ${#BAMS[@]} == 0 )); then
    echo "ERROR: no BAMs found for sample ${SAMPLE} in ${INPUT_DIR}" >&2
    exit 1
fi

echo "Sample: $SAMPLE"
echo "Found ${#BAMS[@]} input BAM(s)"

: > "$MANIFEST"

############################
# pass 1: add RG per BAM
############################

for bam in "${BAMS[@]}"; do
    base=$(basename "$bam")
    echo
    echo "Processing: $base"

    # confirm sample parsed from filename matches requested sample
    if [[ "$base" =~ (CC[0-9]{3}) ]]; then
        sample_from_file="${BASH_REMATCH[1]}"
    else
        echo "ERROR: could not parse sample from filename: $base" >&2
        exit 1
    fi

    if [[ "$sample_from_file" != "$SAMPLE" ]]; then
        echo "ERROR: filename sample ($sample_from_file) does not match requested sample ($SAMPLE): $base" >&2
        exit 1
    fi

    # parse flowcell + lane from filename, e.g. ..._HMHGCCCXX_L005_...
    if [[ "$base" =~ _([A-Za-z0-9]+)_L([0-9]{3})_ ]]; then
        flowcell_file="${BASH_REMATCH[1]}"
        lane_file_padded="${BASH_REMATCH[2]}"
    else
        echo "ERROR: could not parse flowcell/lane from filename: $base" >&2
        exit 1
    fi

    readname=$(get_first_readname "$bam")
    if [[ -z "$readname" ]]; then
        echo "ERROR: no alignments found in $bam" >&2
        exit 1
    fi

    IFS=: read -r instrument run flowcell_read lane_read tile x y <<< "$readname"
    if [[ -z "${y:-}" ]]; then
        echo "ERROR: unexpected read name format in $bam: $readname" >&2
        exit 1
    fi

    lane_read_num=$((10#$lane_read))
    lane_file_num=$((10#$lane_file_padded))
    lane_read_padded=$(printf "%03d" "$lane_read_num")

    # cheap filename vs readname sanity checks
    if [[ "$flowcell_read" != "$flowcell_file" ]]; then
        echo "ERROR: flowcell mismatch for $base" >&2
        echo "  filename: $flowcell_file" >&2
        echo "  readname: $flowcell_read" >&2
        exit 1
    fi

    if (( lane_read_num != lane_file_num )); then
        echo "ERROR: lane mismatch for $base" >&2
        echo "  filename: $lane_file_num" >&2
        echo "  readname: $lane_read_num" >&2
        exit 1
    fi

    if (( CHECK_N_READS > 0 )); then
        echo "Checking first ${CHECK_N_READS} alignments for consistent flowcell/lane"
        check_readname_consistency "$bam" "$flowcell_read" "$lane_read_num" "$CHECK_N_READS"
    fi

    RG_BAM="${SAMPLE_RG_DIR}/${SAMPLE}-${flowcell_read}-L${lane_read_padded}.rg.bam"

    if [[ -e "$RG_BAM" && "$OVERWRITE" -eq 0 ]]; then
        echo "RG BAM already exists, skipping: $RG_BAM"
    else
        samtools addreplacerg \
            -@ "$THREADS" \
            -r "ID:${flowcell_read}-${lane_read_num}" \
            -r "PU:${flowcell_read}.${lane_read_num}.${SAMPLE}" \
            -r "SM:${SAMPLE}" \
            -r "PL:${PLATFORM}" \
            -r "LB:${SAMPLE}-lib1" \
            -o "$RG_BAM" \
            "$bam"
    fi

    printf "%s\t%s\t%s\n" "$SAMPLE" "$RG_BAM" "$bam" >> "$MANIFEST"
done

############################
# pass 2: merge sample RG BAMs
############################

mapfile -t RG_BAMS < <(cut -f2 "$MANIFEST" | sort -u)

if (( ${#RG_BAMS[@]} == 0 )); then
    echo "ERROR: no RG BAMs recorded in manifest for ${SAMPLE}" >&2
    exit 1
fi

echo
echo "Merging ${#RG_BAMS[@]} RG BAM(s) for ${SAMPLE}"

if [[ -e "$MERGED_BAM" && "$OVERWRITE" -eq 0 ]]; then
    echo "Merged BAM already exists, skipping: $MERGED_BAM"
else
    if (( ${#RG_BAMS[@]} == 1 )); then
        samtools view -@ "$THREADS" -b -o "$MERGED_BAM" "${RG_BAMS[0]}"
    else
        samtools merge -@ "$THREADS" -o "$MERGED_BAM" "${RG_BAMS[@]}"
    fi
fi

if [[ ! -e "${MERGED_BAM}.bai" || "$OVERWRITE" -eq 1 ]]; then
    samtools index -@ "$THREADS" "$MERGED_BAM"
fi

echo
echo "Done for ${SAMPLE}"
echo "Manifest: $MANIFEST"
echo "Merged BAM: $MERGED_BAM"
