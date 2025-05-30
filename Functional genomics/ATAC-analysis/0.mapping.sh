#!/bin/bash

# ----------------------------
# 1. Setup and Variables
# ----------------------------

set -e  # Stop on error

SAMPLES=('SAMPLE1' 'SAMPLE2')  # Replace with actual sample names
T=24

script="/path/to/scripts"
OUT="/path/to/output"
pangenome="/path/to/pangenome"
gbz="./CC.full.multi.gbz"
dist="./CC.full.dist"
min="./CC.full.min"
gfa="${pangenome}/CC.full.gfa"

# ----------------------------
# 2. Extracting Paths
# ----------------------------

vg path "${gbz}" > CC_all.path
grep 'mm10' CC_all.path > mm10.path
grep 'CC032' CC_all.path > CC032.path
grep 'CC072' CC_all.path > CC072.path


# ----------------------------
# 3. Mapping and BAM Generation
# ----------------------------

cd "${OUT}"

for NAME in "${SAMPLES[@]}"; do
    F1="${OUT}/1.clean/${NAME}_R1.fastq.gz"
    F2="${OUT}/1.clean/${NAME}_R2.fastq.gz"
    library="${NAME}-lib1"

    # Run trim_galore
    trim_galore -j ${T} -q 36 --length 36 --max_n 3 --stringency 3 --phred33 --paired \
        -a 'CTGTCTCTTATACACATCT' --fastqc -o "${OUT}/1.clean/" "${F1}" "${F2}"
    echo -e "after QC (clean) reads\t$(zcat ${OUT}/1.clean/${NAME}_R1.fastq.gz | wc -l | awk '{print $1/4}')" >> "${OUT}/2.statics/${NAME}_unique_file.txt"

    # Run vg giraffe mapping
    vg giraffe -t 64 -m "${min}" -d "${dist}" -Z "${gbz}" \
        -f "${F1}" -M 2 -f "${F2}" -o gam > "${NAME}_multi.gam"

    # Surject to BAM
    vg surject -t 64 -b -i -N "${NAME}" -R "${library}" -F CC032.path -x "${gbz}" "${NAME}_multi.gam" > "${NAME}_CC032.bam"
    vg surject -t 64 -b -i -N "${NAME}" -R "${library}" -F CC072.path -x "${gbz}" "${NAME}_multi.gam" > "${NAME}_CC072.bam"
    vg surject -t 64 -b -i -N "${NAME}" -R "${library}" -F mm10.path  -x "${gbz}" "${NAME}_multi.gam" > "${NAME}_mm10.bam"
done
