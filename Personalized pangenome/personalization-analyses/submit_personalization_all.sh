#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/vg/bin: directory containing the vg executable selected by --vg-bin; also configurable with --vg-path.
# /path/to/recombinant_fasta_header_fix.py: external recombinant FASTA header-fixing script (not included).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  submit_personalization_all.sh -k KMC_BASE -o OUT_BASE \
    --clip-prefix CLIP_PREFIX --full-prefix FULL_PREFIX \
    [--graph-types LIST] [--path-prefixes LIST] \
    [-P PARTITION] [-T TIME] [-m MEM] [-t THREADS] \
    [--vg-path VG_PATH] [--vg-bin VG_BIN] [--dry-run]

Required:
  -k KMC_BASE          Root containing per-sample subdirs with *.kff
  -o OUT_BASE          Output root (creates OUT_BASE/<graph_type>/<sample>/...)
  --clip-prefix PREFIX Prefix for clip graph files (without trailing gbz/hapl)
  --full-prefix PREFIX Prefix for full graph files (without trailing gbz/hapl)

Optional:
  --graph-types LIST   Comma-separated graph types to run (default: clip,full)
  --path-prefixes LIST Comma-separated deconstruct path prefixes (default: mm10,GRCm39)
  -P PARTITION         Slurm partition (default: cluster default)
  -T TIME              Slurm time (default: 144:00:00)
  -m MEM               Slurm memory (default: 200G)
  -t THREADS           Threads / cpus-per-task (default: 10)
  --vg-path PATH       Directory added to PATH inside jobs (default: /path/to/vg/bin)
  --vg-bin BIN         vg executable name (default: vg_1.61.0)
  --dry-run            Print what would be submitted, but do not sbatch

Notes:
- Loops over ALL immediate subdirectories of KMC_BASE (no CC*/SRR* assumption).
- Uses the first *.kff if multiple are found in a sample directory.
- For each graph type, expects:
    <PREFIX>gbz and <PREFIX>hapl
EOF
}

KMC_BASE=""
OUT_BASE=""
CLIP_PREFIX=""
FULL_PREFIX=""

VG_PATH="/path/to/vg/bin"
VG_BIN="vg_1.61.0"

THREADS=10
MEM="164G"
PARTITION=""  # Slurm partition to submit to; empty uses your cluster's default
DRY_RUN=0

GRAPH_TYPES="clip,full"
PATH_PREFIXES="mm10"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -k) KMC_BASE="$2"; shift 2 ;;
    -o) OUT_BASE="$2"; shift 2 ;;
    --clip-prefix) CLIP_PREFIX="$2"; shift 2 ;;
    --full-prefix) FULL_PREFIX="$2"; shift 2 ;;
    --graph-types) GRAPH_TYPES="$2"; shift 2 ;;
    --path-prefixes) PATH_PREFIXES="$2"; shift 2 ;;
    -P) PARTITION="$2"; shift 2 ;;
    -T) TIME="$2"; shift 2 ;;
    -m) MEM="$2"; shift 2 ;;
    -t) THREADS="$2"; shift 2 ;;
    --vg-path) VG_PATH="$2"; shift 2 ;;
    --vg-bin) VG_BIN="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "${KMC_BASE}" || -z "${OUT_BASE}" || -z "${CLIP_PREFIX}" || -z "${FULL_PREFIX}" ]]; then
  echo "Error: -k, -o, --clip-prefix, and --full-prefix are required." >&2
  usage
  exit 1
fi

if [[ ! -d "${KMC_BASE}" ]]; then
  echo "Error: KMC_BASE is not a directory: ${KMC_BASE}" >&2
  exit 1
fi

mkdir -p "${OUT_BASE}"

declare -A PREFIX
PREFIX[clip]="${CLIP_PREFIX}"
PREFIX[full]="${FULL_PREFIX}"

IFS=',' read -r -a graph_types_arr <<< "${GRAPH_TYPES}"

shopt -s nullglob

for graph_type in "${graph_types_arr[@]}"; do
  if [[ -z "${PREFIX[$graph_type]+x}" ]]; then
    echo "Error: no prefix provided for graph_type '${graph_type}'." >&2
    exit 1
  fi

  GRAPH_GBZ="${PREFIX[$graph_type]}gbz"
  GRAPH_HAPL="${PREFIX[$graph_type]}hapl"

  if [[ ! -f "${GRAPH_GBZ}" || ! -f "${GRAPH_HAPL}" ]]; then
    echo "Missing graph files for ${graph_type}:" >&2
    echo "  ${GRAPH_GBZ}" >&2
    echo "  ${GRAPH_HAPL}" >&2
    exit 1
  fi

  for sample_dir in "${KMC_BASE}"/*; do
    [[ -d "$sample_dir" ]] || continue
    sample=$(basename "$sample_dir")

    mapfile -t kffs < <(ls -1 "${sample_dir}"/*.kff 2>/dev/null || true)
    if [[ ${#kffs[@]} -eq 0 ]]; then
      echo "Missing .kff in ${sample_dir} (skip ${graph_type}/${sample})" >&2
      continue
    fi
    if [[ ${#kffs[@]} -gt 1 ]]; then
      echo "Multiple .kff found in ${sample_dir}; using the first one:" >&2
      printf "  %s\n" "${kffs[@]}" >&2
    fi
    KMCKFF="${kffs[0]}"

    out_dir="${OUT_BASE}/${graph_type}/${sample}"
    mkdir -p "$out_dir"

    if [[ "${DRY_RUN}" -eq 1 ]]; then
      echo "Would submit ${graph_type}/${sample}"
      echo "  kff:  ${KMCKFF}"
      echo "  gbz:  ${GRAPH_GBZ}"
      echo "  hapl: ${GRAPH_HAPL}"
      echo "  out:  ${out_dir}"
      continue
    fi

    sbatch ${PARTITION:+--partition="$PARTITION"} <<EOF
#!/bin/bash -l
#SBATCH --job-name=pers_${graph_type}_${sample}
#SBATCH --cpus-per-task=${THREADS}
#SBATCH --mem=${MEM}
#SBATCH --output=${out_dir}/pers_%j.out
#SBATCH --error=${out_dir}/pers_%j.err

set -euo pipefail

export PATH=${VG_PATH}:\$PATH
cd ${out_dir}

echo "[INFO] graph_type=${graph_type}"
echo "[INFO] sample=${sample}"
echo "[INFO] kff=${KMCKFF}"
echo "[INFO] gbz=${GRAPH_GBZ}"
echo "[INFO] hapl=${GRAPH_HAPL}"
echo "[INFO] path_prefixes=${PATH_PREFIXES}"

# 1) haplotype sampling
${VG_BIN} haplotypes -v 2 -t ${THREADS} --include-reference --preset diploid --diploid-sampling \\
  -i ${GRAPH_HAPL} -k ${KMCKFF} -g sampled.gbz ${GRAPH_GBZ}

# 2) deconstruct (one VCF per reference prefix)
IFS=',' read -r -a PREFS <<< "${PATH_PREFIXES}"
for pref in "\${PREFS[@]}"; do
  ${VG_BIN} deconstruct --path-prefix "\${pref}" -t ${THREADS} --verbose sampled.gbz > "deconstruct.\${pref}.vcf"
done

# 3) recombinant FASTA
${VG_BIN} paths --extract-fasta -x sampled.gbz -t ${THREADS} --paths-by recombination#1 > r1.fasta
${VG_BIN} paths --extract-fasta -x sampled.gbz -t ${THREADS} --paths-by recombination#2 > r2.fasta

# 4) fix FASTA headers
python3 /path/to/recombinant_fasta_header_fix.py r1.fasta r1f.fasta
python3 /path/to/recombinant_fasta_header_fix.py r2.fasta r2f.fasta
EOF

    echo "submitted ${graph_type}/${sample}"
  done
done