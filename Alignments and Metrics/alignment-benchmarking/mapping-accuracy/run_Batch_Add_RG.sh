#!/bin/bash
#SBATCH --mem=8G
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --cpus-per-task=8
#SBATCH -J Add_RG

read -r INPUT OUTPUT RGID RGPU RGSM RGPL RGLB < <( sed -n "${SLURM_ARRAY_TASK_ID}p" "$1" )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools@1.13/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)
eval $( spack load --sh picard/z5udlmv )   # picard, version not recorded (build hash z5udlmv)

# print parameters to log
echo "INPUT: $INPUT"
echo "OUTPUT: $OUTPUT"
echo "RGID: $RGID"
echo "RGPU: $RGPU"
echo "RGSM: $RGSM"
echo "RGPL: $RGPL"
echo "RGLB: $RGLB"
# Example RG: "@RG\tID:CC001-lib1\tPU:CC001-lib1\tSM:CC001\tPL:ILLUMINA\tLB:CC001-lib1"

#RG=$(printf '%b' "$RG")

tmpbam="${INPUT%.bam}.rgfix.bam"

picard AddOrReplaceReadGroups \
       I=$INPUT \
       O=$tmpbam \
       RGID=$RGID \
       RGLB=$RGLB \
       RGPL=$RGPL \
       RGPU=$RGPU \
       RGSM=$RGSM

#samtools addreplacerg \
#    -@ 8 \
#    -O BAM \
#    -r "$RG" \
#    -o "$tmpbam" \
#    "$INPUT"

mv "$tmpbam" "$OUTPUT"
samtools index -@ 8 "$OUTPUT"

echo "Done!"