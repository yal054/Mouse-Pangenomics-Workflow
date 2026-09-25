#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/rmblast-2.14.1/bin: directory containing RMBlast executables.
# /path/to/TRF: directory containing the TRF executable.
# /path/to/RepeatMasker/RepeatMasker: RepeatMasker executable.
#SBATCH --mem=32000
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=10
#SBATCH -J RepMask

# [RepeatMasker parameters lookup file]
read INPUTFASTA SPECIES < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Input fasta: "$INPUTFASTA

echo "Loading RepeatMasker..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh perl/ipla2d37jyp7rxojdjwiutawolqfxaeg )   # perl, version not recorded (build hash ipla2d37jyp7rxojdjwiutawolqfxaeg)
eval $( spack load --sh py-h5py/v2g7dt6 )   # py-h5py, version not recorded (build hash v2g7dt6)
export PATH=/path/to/rmblast-2.14.1/bin:/path/to/TRF:$PATH

echo "Running RepeatMasker..."
/path/to/RepeatMasker/RepeatMasker \
  -species $SPECIES \
  -pa 10 \
  $INPUTFASTA

echo "Complete!"