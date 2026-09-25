#!/bin/bash
#SBATCH --mem=2G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J calc_pairwise_allele_10kb_bins
#SBATCH --cpus-per-task=1

read INPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "INPUT: $INPUT"

echo "Calculating 10kb binned averages..."
awk 'BEGIN{OFS="\t"}
$6 != "NA" {
    bin_start = int($2/10000)*10000
    bin_end = bin_start + 10000
    key = $1 FS bin_start FS bin_end
    sum[key] += $6
    n[key]++
}
END {
    for (key in sum) {
        print key, sum[key]/n[key], n[key]
    }
}' $INPUT > ${INPUT%.tsv}_10kb_bins.tsv

echo "Done!"