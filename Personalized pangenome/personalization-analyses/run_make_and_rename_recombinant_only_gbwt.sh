#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/vg: vg executable; use the version described in the manuscript.
#SBATCH --mem=96G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=8
#SBATCH -J make_gbwt

read GBZ SAMPLE OUTD REFS_TO_DROP < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

TMPDIR=${OUTD}/tmp_${SAMPLE}
mkdir -p "$TMPDIR"

GFA_RAW=${TMPDIR}/${SAMPLE}.raw.gfa
GFA_EDIT=${TMPDIR}/${SAMPLE}.rename.gfa
GBWT_WITHREF=${TMPDIR}/${SAMPLE}.withrefs.gbwt
GBWT_ONLY=${OUTD}/${SAMPLE}.gbwt

echo "Input file: $GBZ"
echo "Sample: $SAMPLE"
echo "Output dir: $OUTD"

echo "Starting GBZ -> GFA..."
/path/to/vg convert -t 8 -f "$GBZ" > "$GFA_RAW"
echo " Complete!"

echo "Renaming recombination -> $SAMPLE ..."
awk -v S="$SAMPLE" 'BEGIN{FS=OFS="\t"}{
  if ($1=="W" && $2=="recombination") $2=S;
  print
}' "$GFA_RAW" > "$GFA_EDIT"
echo " Complete!"

echo "Building GBWT..."
/path/to/vg gbwt --num-threads 8 -G --max-node 0 -o "$GBWT_WITHREF" "$GFA_EDIT"
echo " Complete!"

echo "Removing reference samples..."

# Build -R arguments from comma-delimited REFS_TO_DROP
R_ARGS=""
if [ -n "${REFS_TO_DROP}" ]; then
  IFS=',' read -r -a REF_ARR <<< "${REFS_TO_DROP}"
  for R in "${REF_ARR[@]}"; do
    # trim leading/trailing whitespace just in case
    R_CLEAN=$(echo "$R" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    if [ -n "$R_CLEAN" ]; then
      R_ARGS="${R_ARGS} -R ${R_CLEAN}"
    fi
  done
fi

if [ -n "$R_ARGS" ]; then
  # shellcheck disable=SC2086
  /path/to/vg gbwt --num-threads 8 \
    -o "$GBWT_ONLY" \
    $R_ARGS \
    "$GBWT_WITHREF"
else
  echo " No references specified, copying GBWT without removal..."
  cp -f "$GBWT_WITHREF" "$GBWT_ONLY"
fi

echo " Complete!"

echo "Sanity check:"
/path/to/vg gbwt --num-threads 1 -S -L "$GBWT_ONLY"

rm -f "$GFA_RAW" "$GFA_EDIT" "$GBWT_WITHREF"
rmdir "$TMPDIR" 2>/dev/null || true

echo "Done."