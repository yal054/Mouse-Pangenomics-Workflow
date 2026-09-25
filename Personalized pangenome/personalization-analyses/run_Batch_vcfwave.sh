#!/bin/bash
# Local setup: replace every /path/to placeholder below before running.
# /path/to/vcfbub: vcfbub executable.
# /path/to/vcfwave: vcfwave executable.
#SBATCH --mem=16000
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=4
#SBATCH -J vcfwave_contig

set -euo pipefail

# [Parameter lookup file]
read INPUTVCF CONTIG < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Input VCF: "$INPUTVCF
echo "Contig: "$CONTIG

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh bcftools/yz7hzwn )   # bcftools 1.12 (build hash yz7hzwn)
eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)

eval $( spack load --sh gcc/g7v66i6 )   # gcc, version not recorded (build hash g7v66i6)
eval $( spack load --sh cmake/6mjoqms )   # cmake, version not recorded (build hash 6mjoqms)
eval $( spack load --sh bzip2/rr5pqdl )   # bzip2, version not recorded (build hash rr5pqdl)
eval $( spack load --sh xz/mfhopfi )   # xz, version not recorded (build hash mfhopfi)
eval $( spack load --sh zlib/2qdrps4 )   # zlib, version not recorded (build hash 2qdrps4)
eval $( spack load --sh pkgconf/r2fdlro )   # pkgconf, version not recorded (build hash r2fdlro)
eval $( spack load --sh py-pybind11/bqseav2 )   # py-pybind11, version not recorded (build hash bqseav2)
eval $( spack load --sh curl@7.79.0%gcc@11.4.1 )
eval $( spack load --sh libdeflate@1.7%gcc@11.4.1 )

if [[ "$INPUTVCF" == *.vcf.gz ]]; then
    OUTPUTVCF=${INPUTVCF%.vcf.gz}.${CONTIG}.vcfbub.r100k.wave.vcf.gz
elif [[ "$INPUTVCF" == *.vcf ]]; then
    OUTPUTVCF=${INPUTVCF%.vcf}.${CONTIG}.vcfbub.r100k.wave.vcf.gz
else
    echo "ERROR: input must end in .vcf or .vcf.gz"
    exit 1
fi

TMPINPUT=${OUTPUTVCF%.vcf.gz}.input.vcf.gz
TMPVCFBUB=${OUTPUTVCF%.vcf.gz}.vcfbub.vcf
TMPWAVE=${OUTPUTVCF%.vcf.gz}.wave.vcf

echo "Output VCF: "$OUTPUTVCF

echo "Extracting contig..."
bcftools view $INPUTVCF -r $CONTIG | bgzip > $TMPINPUT
tabix -fp vcf $TMPINPUT

echo "Running vcfbub..."
/path/to/vcfbub \
  --input $TMPINPUT \
  -l 0 \
  -r 100000 \
  > $TMPVCFBUB

echo "Running vcfwave..."
/path/to/vcfwave \
  -t 2 \
  -I 1000 \
  $TMPVCFBUB \
  > $TMPWAVE

echo "Compressing output..."
bgzip -c $TMPWAVE > $OUTPUTVCF
tabix -fp vcf $OUTPUTVCF

echo "Cleaning up..."
rm -f $TMPINPUT
rm -f ${TMPINPUT}.tbi
rm -f $TMPVCFBUB
rm -f $TMPWAVE

echo "Complete!"
echo "Output: "$OUTPUTVCF