#!/bin/bash
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
#SBATCH -N 1
#SBATCH -J fastp

# [Alignment parameters lookup file]
read READ1 READ2 OUTPUT1 OUTPUT2 TRIMLOG < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

adapter_1="CTGTCTCTTATACACATCT"
adapter_2="CTGTCTCTTATACACATCT"

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh fastp@0.20.0 )


# check to make sure input files exist
if [ ! -f "$READ1" ]; then
  echo "Error: Input file "$READ1" not found!"
  exit 1
fi

if [ ! -f "$READ2" ]; then
  echo "Error: Input file "$READ2" not found!"
  exit 1
fi

echo "Input files: "$READ1" "$READ2
echo "Output files: "$OUTPUT1" "$OUTPUT2
echo "Trim log: "$TRIMLOG

echo "Starting Trim..."
fastp \
  -i "$READ1" -I "$READ2" \
  -o "$OUTPUT1" -O "$OUTPUT2" \
  -a "$adapter_1" --adapter_sequence_r2 "$adapter_2" \
  -5 -3 \
  --cut_front_mean_quality 15 \
  --cut_tail_mean_quality 10 \
  --cut_front_window_size 1 \
  --cut_tail_window_size 1 \
  -l 36 \
  -Q \
  -w 1 \
  -j "${TRIMLOG%.log}.json" \
  -h "${TRIMLOG%.log}.html" \
  > "$TRIMLOG" 2>&1

echo " ...Complete!"

