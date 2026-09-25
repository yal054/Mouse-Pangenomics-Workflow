#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/score_mosaic_concordance.py: script included in this repository at `Personalized pangenome/personalization-analyses/score_mosaic_concordance.py`.
#SBATCH --mem=8G
#SBATCH -n 1
#SBATCH -N 1

read VCF SAMPLE HAPL OUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
# python 3
eval $( spack load --sh python/si3fu6h )

echo "vcf file: $VCF"
echo "sample: $SAMPLE"
echo "haplotype: $HAPL"
echo "output: $OUT"

# check to make sure vcf, and haplotype files exist
if [ ! -f $VCF ]; then
    echo "Error: VCF file $VCF does not exist."
    exit 1
fi

if [ ! -f $HAPL ]; then
    echo "Error: Haplotype file $HAPL does not exist."
    exit 1
fi

# start time measurement
start_time=$(date +%s)
echo "Running script..."
python3 /path/to/score_mosaic_concordance.py \
  --vcf $VCF \
  --sample $SAMPLE \
  --hapl $HAPL \
  --out $OUT

end_time=$(date +%s)
elapsed_time=$(( end_time - start_time ))
echo "Elapsed time: $elapsed_time seconds"
