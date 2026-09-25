#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/KMC/bin: directory containing KMC executables.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run_kmc.sh -i INDIR -o OUTROOT [-k K] [-t THREADS] [-m MEM_GB] [-p PARTITION] [-T TIME] [-M KMC_MAX_GB] [--dry-run]

Required:
  -i INDIR      Directory containing paired FASTQs
  -o OUTROOT    Output root directory (one subdir per sample)

Optional:
  -k K          K-mer size (default: 29)
  -t THREADS    Threads for KMC and Slurm cpus-per-task (default: 20)
  -m MEM_GB     Slurm memory (default: 150G)
  -p PARTITION  Slurm partition (default: cluster default)
  -T TIME       Slurm time (default: 144:00:00)
  -M KMC_MAX_GB KMC -m value (GB, default: 128)
  --dry-run     Print what would be submitted, but do not sbatch

Assumed FASTQ naming conventions for paired-end:
  *_R1.fastq.gz      <-> *_R2.fastq.gz
  *_R1_001.fastq.gz  <-> *_R2_001.fastq.gz
  *_1.fastq.gz       <-> *_2.fastq.gz
  (also supports *.fq.gz variants)
EOF
}

INDIR=""
OUTROOT=""

K=29
THREADS=20
SLURM_MEM="150G"
PARTITION=""  # Slurm partition to submit to; empty uses your cluster's default
TIME="144:00:00"
KMC_M=128
DRY_RUN=0

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i) INDIR="$2"; shift 2 ;;
    -o) OUTROOT="$2"; shift 2 ;;
    -k) K="$2"; shift 2 ;;
    -t) THREADS="$2"; shift 2 ;;
    -m) SLURM_MEM="$2"; shift 2 ;;
    -p) PARTITION="$2"; shift 2 ;;
    -T) TIME="$2"; shift 2 ;;
    -M) KMC_M="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "${INDIR}" || -z "${OUTROOT}" ]]; then
  echo "Error: -i INDIR and -o OUTROOT are required." >&2
  usage
  exit 1
fi

if [[ ! -d "${INDIR}" ]]; then
  echo "Error: INDIR does not exist or is not a directory: ${INDIR}" >&2
  exit 1
fi

mkdir -p "${OUTROOT}"

export PATH=/path/to/KMC/bin:$PATH

shopt -s nullglob

r2_from_r1() {
  local r1="$1"
  local r2=""

  if [[ "$r1" == *"_R1_001.fastq.gz" ]]; then
    r2="${r1/_R1_001.fastq.gz/_R2_001.fastq.gz}"
  elif [[ "$r1" == *"_R1_001.fq.gz" ]]; then
    r2="${r1/_R1_001.fq.gz/_R2_001.fq.gz}"
  elif [[ "$r1" == *"_R1.fastq.gz" ]]; then
    r2="${r1/_R1.fastq.gz/_R2.fastq.gz}"
  elif [[ "$r1" == *"_R1.fq.gz" ]]; then
    r2="${r1/_R1.fq.gz/_R2.fq.gz}"
  elif [[ "$r1" == *"_1.fastq.gz" ]]; then
    r2="${r1/_1.fastq.gz/_2.fastq.gz}"
  elif [[ "$r1" == *"_1.fq.gz" ]]; then
    r2="${r1/_1.fq.gz/_2.fq.gz}"
  else
    r2=""
  fi

  printf "%s" "$r2"
}

sample_from_r1() {
  local r1
  r1="$(basename "$1")"

  if [[ "$r1" == *"_R1_001.fastq.gz" ]]; then
    printf "%s" "${r1%_R1_001.fastq.gz}"
  elif [[ "$r1" == *"_R1_001.fq.gz" ]]; then
    printf "%s" "${r1%_R1_001.fq.gz}"
  elif [[ "$r1" == *"_R1.fastq.gz" ]]; then
    printf "%s" "${r1%_R1.fastq.gz}"
  elif [[ "$r1" == *"_R1.fq.gz" ]]; then
    printf "%s" "${r1%_R1.fq.gz}"
  elif [[ "$r1" == *"_1.fastq.gz" ]]; then
    printf "%s" "${r1%_1.fastq.gz}"
  elif [[ "$r1" == *"_1.fq.gz" ]]; then
    printf "%s" "${r1%_1.fq.gz}"
  else
    printf "%s" ""
  fi
}

r1_candidates=(
  "${INDIR}"/*_R1.fastq.gz
  "${INDIR}"/*_R1_001.fastq.gz
  "${INDIR}"/*_1.fastq.gz
  "${INDIR}"/*_R1.fq.gz
  "${INDIR}"/*_R1_001.fq.gz
  "${INDIR}"/*_1.fq.gz
)

if [[ ${#r1_candidates[@]} -eq 0 ]]; then
  echo "No R1 fastq files found in ${INDIR} using supported patterns." >&2
  exit 1
fi

for r1 in "${r1_candidates[@]}"; do
  [[ -s "$r1" ]] || continue

  r2="$(r2_from_r1 "$r1")"
  if [[ -z "$r2" ]]; then
    echo "Could not infer R2 name from R1: $r1 (skip)" >&2
    continue
  fi
  if [[ ! -s "$r2" ]]; then
    echo "Missing R2 for R1: $r1" >&2
    echo "Expected R2:        $r2" >&2
    echo "Skip" >&2
    continue
  fi

  s="$(sample_from_r1 "$r1")"
  if [[ -z "$s" ]]; then
    echo "Could not infer sample name from R1: $r1 (skip)" >&2
    continue
  fi

  outdir="${OUTROOT}/${s}"
  mkdir -p "${outdir}"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "Would submit: sample=${s}"
    echo "  R1: ${r1}"
    echo "  R2: ${r2}"
    echo "  OUT: ${outdir}"
    continue
  fi

  sbatch ${PARTITION:+--partition="$PARTITION"} <<EOF
#!/bin/bash -l
#SBATCH --job-name=kmc_${s}
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=${THREADS}
#SBATCH --time=${TIME}
#SBATCH --mem=${SLURM_MEM}
#SBATCH --output=${outdir}/kmc_%j.out
#SBATCH --error=${outdir}/kmc_%j.err

set -euo pipefail
export PATH=/path/to/KMC/bin:\$PATH

cd "${outdir}"

echo "${r1}" > ${s}.fq.list
echo "${r2}" >> ${s}.fq.list

kmc -k${K} -m${KMC_M} -okff -t${THREADS} -hp @${s}.fq.list ${s}.kmc ./
EOF

  echo "submitted ${s}"
done