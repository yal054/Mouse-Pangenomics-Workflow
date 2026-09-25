#!/bin/bash
#SBATCH --mem=6G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J pairwise_site_sharing
#SBATCH --cpus-per-task=1

read VCF SAMPLE1 SAMPLE2 OUTPUT < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh bcftools/yz7hzwn )   # bcftools 1.12 (build hash yz7hzwn)

echo "VCF: $VCF"
echo "SAMPLE1: $SAMPLE1"
echo "SAMPLE2: $SAMPLE2"
echo "OUTPUT: $OUTPUT"

echo "Running pairwise site sharing calculation..."
bcftools query \
  -s ${SAMPLE1},${SAMPLE2} \
  -f '%CHROM\t%POS\t%REF\t[%GT\t]\n' \
  $VCF | \
awk 'BEGIN{OFS="\t"}
function frac_shared(gt1, gt2,   a,b,i,n1,n2,shared,key) {
    gsub(/\|/, "/", gt1)
    gsub(/\|/, "/", gt2)

    if (gt1 ~ /\./ || gt2 ~ /\./) return "NA"

    split(gt1, a, "/")
    split(gt2, b, "/")

    delete n1
    delete n2

    for (i=1; i<=2; i++) {
        n1[a[i]]++
        n2[b[i]]++
    }

    shared=0
    for (key in n1) {
        if (key in n2) {
            if (n1[key] < n2[key]) {
                shared += n1[key]
            } else {
                shared += n2[key]
            }
        }
    }

    return shared/2
}
{
    chrom=$1
    pos=$2
    ref=$3
    gt1=$4
    gt2=$5
    start=pos-1
    stop=start+length(ref)
    print chrom, start, stop, gt1, gt2, frac_shared(gt1, gt2)
}' > $OUTPUT

echo "Done!"