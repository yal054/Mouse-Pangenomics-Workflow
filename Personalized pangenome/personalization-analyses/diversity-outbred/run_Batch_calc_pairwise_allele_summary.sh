#!/bin/bash
#SBATCH --mem=3G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J calc_pairwise_allele_summary
#SBATCH --cpus-per-task=1

read INPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "INPUT: $INPUT"

echo "Calculating summary statistics..."
awk 'BEGIN{
    n0=0; n05=0; n1=0; nna=0; sum=0; n=0
}
{
    val=$6

    if (val=="NA") {
        nna++
    } else {
        n++
        sum += val

        if (val==0) {
            n0++
        } else if (val==0.5) {
            n05++
        } else if (val==1) {
            n1++
        }
    }
}
END{
    print "count_0\t" n0
    print "count_0.5\t" n05
    print "count_1\t" n1
    print "count_NA\t" nna
    print "informative_sites\t" n
    if (n>0) {
        print "overall_concordance_rate\t" n1/n
        print "genome_wide_fraction_alleles_shared\t" sum/n
    } else {
        print "overall_concordance_rate\tNA"
        print "genome_wide_fraction_alleles_shared\tNA"
    }
}' $INPUT > ${INPUT%.tsv}_summary.tsv

echo "Done!"