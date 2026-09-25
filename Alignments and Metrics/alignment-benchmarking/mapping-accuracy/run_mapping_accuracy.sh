#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/mapping_accuracy_env/bin/activate: activation script for your mapping-accuracy Python environment.
# /path/to/repo: absolute path to your clone of this repository.
#SBATCH --mem=4G
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=1
#SBATCH --job-name=mapping_accuracy

set -euo pipefail

read WORKDIR CONFIGFILE < <(sed -n ${SLURM_ARRAY_TASK_ID}p $1)

# Resolve absolute paths before changing directory
CONFIGFILE=$(readlink -f "$CONFIGFILE")
CONFIGDIR=$(dirname "$CONFIGFILE")

echo "Creating working directory: $WORKDIR"
mkdir -p "$WORKDIR"
mkdir -p "$WORKDIR/logs/job_ids"
cd "$WORKDIR"

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval "$(spack load --sh python/wcs7jsf)"   # python 3.8.12 (build hash wcs7jsf)

echo "Activating environment..."
source /path/to/mapping_accuracy_env/bin/activate

# Symlink inputs into working directory
echo "Symlinking inputs..."
python3 << PYEOF
import yaml, os, sys

config = yaml.safe_load(open('${CONFIGFILE}'))
config_dir = '${CONFIGDIR}'

# BAM
bam = config['bam']
if not os.path.isabs(bam):
    bam = os.path.join(config_dir, bam)
bam = os.path.realpath(bam)
if not os.path.exists(bam):
    print(f"ERROR: BAM not found: {bam}", file=sys.stderr)
    sys.exit(1)
link = os.path.basename(bam)
if not os.path.exists(link):
    os.symlink(bam, link)
    print(f"  {link} -> {bam}")

# PAF indexes
for rg, paf in config['read_groups'].items():
    if not os.path.isabs(paf):
        paf = os.path.join(config_dir, paf)
    paf = os.path.realpath(paf)
    if not os.path.exists(paf):
        print(f"ERROR: PAF index not found: {paf}", file=sys.stderr)
        sys.exit(1)
    rel = config['read_groups'][rg]
    parent = os.path.dirname(rel)
    if parent:
        os.makedirs(parent, exist_ok=True)
    if not os.path.exists(rel):
        os.symlink(paf, rel)
        print(f"  {rel} -> {paf}")
PYEOF

echo "Running Snakemake..."
snakemake \
    --snakefile "/path/to/repo/Alignments and Metrics/alignment-benchmarking/mapping-accuracy/Mapping_Accuracy_SnakeMake/Snakefile" \
    --configfile "${CONFIGFILE}" \
    --slurm \
    --jobs 2

# Move snakemake SLURM logs into organized directory
if [ -d .snakemake/slurm_logs ]; then
    mkdir -p logs/rule_slurm_logs
    for d in .snakemake/slurm_logs/rule_*/; do
        [ -d "$d" ] || continue
        rule_name=$(basename "$d")
        mv "$d" "logs/rule_slurm_logs/$rule_name"
    done
fi

echo "Done."