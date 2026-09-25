#!/bin/bash
#SBATCH --mem=8G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J fasterq-dump

read SRAFILE < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# Load the software
eval $( spack load --sh sratoolkit@3.1.1 )

echo "SRA file: "$SRAFILE

# Check the input exists. A missing .sra makes fasterq-dump exit 3; without this check the task
# would still exit 0 and be recorded as COMPLETED.
if [[ ! -s $SRAFILE ]]; then
  echo "Error: SRA file not found or empty: $SRAFILE"
  echo "  note: prefetch writes <ACCESSION>/<ACCESSION>.sra, not <dir>/<ACCESSION>.sra"
  exit 1
fi

echo "Starting fasterq-dump..."
fasterq-dump $SRAFILE
rc=$?

# Propagate fasterq-dump failures (disk full, corrupt .sra, quota, bad path).
if [[ $rc -ne 0 ]]; then
  echo "Error: fasterq-dump exited $rc"
  exit $rc
fi

# A zero exit does not guarantee output, so check that non-empty FASTQs were written.
ACCESSION=$(basename "$SRAFILE" .sra)
shopt -s nullglob
PRODUCED=( "${ACCESSION}"*.fastq )
shopt -u nullglob
if [[ ${#PRODUCED[@]} -eq 0 ]]; then
  echo "Error: fasterq-dump reported success but wrote no ${ACCESSION}*.fastq in $(pwd)"
  exit 1
fi
for f in "${PRODUCED[@]}"; do
  if [[ ! -s $f ]]; then
    echo "Error: $f was created but is empty"
    exit 1
  fi
  echo "  wrote $f ($(du -h "$f" | cut -f1))"
done

echo " Complete!"