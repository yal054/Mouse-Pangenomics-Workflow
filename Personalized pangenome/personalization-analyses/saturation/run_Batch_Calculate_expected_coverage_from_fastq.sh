#!/bin/bash
#SBATCH --mem=4G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J calcCov
#SBATCH --cpus-per-task=20

read FASTQ READ_LENGTH GENOME_SIZE PAIRED < <( sed -n "${SLURM_ARRAY_TASK_ID}p" "$1" )

echo "Fastq: $FASTQ"
echo "Read length: $READ_LENGTH"
echo "Genome size: $GENOME_SIZE"
echo "Paired: $PAIRED"

OUTPUT="${FASTQ}.coverage"

echo "Output: $OUTPUT"

if [[ ! -f "$FASTQ" ]]; then
  echo "ERROR: FASTQ file not found: $FASTQ" >&2
  exit 1
fi

if [[ -z "$READ_LENGTH" || -z "$GENOME_SIZE" || -z "$PAIRED" ]]; then
  echo "ERROR: Missing one or more required fields from parameter file line ${SLURM_ARRAY_TASK_ID}" >&2
  exit 1
fi

echo "Determining decompression command..."

if [[ "$FASTQ" == *.gz ]]; then
  DECOMPRESS_CMD="pigz -p ${SLURM_CPUS_PER_TASK} -dc"
else
  DECOMPRESS_CMD="cat"
fi

echo "Calculating coverage..."

READS=$( $DECOMPRESS_CMD "$FASTQ" | awk 'END {print NR/4}' )

if [[ -z "$READS" ]]; then
  echo "ERROR: Failed to calculate read count." >&2
  exit 1
fi

PAIR_MULTIPLIER=1

case "$PAIRED" in
  TRUE|true|True|1|YES|yes|Yes)
    PAIR_MULTIPLIER=2
    ;;
  FALSE|false|False|0|NO|no|No)
    PAIR_MULTIPLIER=1
    ;;
  *)
    echo "ERROR: PAIRED must be one of TRUE/FALSE, true/false, 1/0, yes/no" >&2
    exit 1
    ;;
esac

COVERAGE=$(awk -v reads="$READS" -v read_length="$READ_LENGTH" -v genome_size="$GENOME_SIZE" -v pair_multiplier="$PAIR_MULTIPLIER" 'BEGIN {printf "%.10f\n", (reads * read_length * pair_multiplier) / genome_size}')

echo "Writing output..."

echo -e "${FASTQ}\t${READ_LENGTH}\t${GENOME_SIZE}\t${PAIRED}\t${COVERAGE}" > "$OUTPUT"

echo "Done!"