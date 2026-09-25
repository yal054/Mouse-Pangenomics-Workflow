#!/bin/bash
#SBATCH --mem=32G
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -J minimap2_alignment
#SBATCH --cpus-per-task=3

read ReferenceFasta QueryFasta OutputPAF < <(sed -n "${SLURM_ARRAY_TASK_ID}p" "$1")

if [[ $OutputPAF != *.paf ]]; then
  echo "Error: OutputPAF must end with .paf (case sensitive)"
  exit 1
fi

echo "Running minimap2 alignment with the following parameters:"
echo "  ReferenceFasta: $ReferenceFasta"
echo "  QueryFasta:     $QueryFasta"
echo "  OutputPAF:      $OutputPAF"
date

echo "Loading modules..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval "$(spack load --sh minimap2@2.28)"

echo "Running minimap2 alignment..."
minimap2 -x asm10 -c --cs -t 3 "$ReferenceFasta" "$QueryFasta" > "$OutputPAF"

if [[ ! -s $OutputPAF ]]; then
  echo "Error: PAF file was not created or is empty."
  exit 1
fi

echo "Alignment complete!"
date