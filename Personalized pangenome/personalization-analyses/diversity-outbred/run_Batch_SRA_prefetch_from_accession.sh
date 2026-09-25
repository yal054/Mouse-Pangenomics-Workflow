#!/bin/bash
#SBATCH --mem=8G
#SBATCH -n 1
#SBATCH -N 1

read ACCESSION < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# Load the software
eval $( spack load --sh sratoolkit@3.1.1 )

# Define the accession file
echo "Accession file: "$ACCESSION

# Define the prefetch function
echo "Starting prefetching..."
prefetch --max-size 60G $ACCESSION
rc=$?

# Fail the task if prefetch fails; prefetch validates its download and returns non-zero on error.
if [[ $rc -ne 0 ]]; then
  echo "Error: prefetch exited $rc for $ACCESSION"
  exit $rc
fi

# Report the output path. prefetch writes <ACCESSION>/<ACCESSION>.sra relative to the working
# directory, so a downstream manifest built as <somedir>/<ACCESSION>.sra will not resolve.
SRA="${ACCESSION}/${ACCESSION}.sra"
if [[ -s $SRA ]]; then
  echo "  wrote $(pwd)/$SRA ($(du -h "$SRA" | cut -f1))"
else
  # Not fatal: the output location is configurable in the SRA toolkit settings, so a missing
  # file here does not prove failure when rc was 0.
  echo "  NOTE: prefetch returned 0 but $SRA is not present in $(pwd)."
  echo "        If your toolkit config redirects output, confirm the .sra location before"
  echo "        building a downstream manifest."
fi

echo " Complete!"