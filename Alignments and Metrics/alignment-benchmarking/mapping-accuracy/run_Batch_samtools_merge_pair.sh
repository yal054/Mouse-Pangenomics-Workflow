#!/bin/bash
#SBATCH --mem=8G
#SBATCH -n 1
#SBATCH -N 1

read INPUTONE INPUTTWO OUTPUTBAM < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools@1.13/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)

# print parameters to log
echo "INPUTONE: $INPUTONE"
echo "INPUTTWO: $INPUTTWO"
echo "OUTPUTBAM: $OUTPUTBAM"

echo "Samtools merge..."
samtools merge -o $OUTPUTBAM $INPUTONE $INPUTTWO

echo "Samtools index..."
samtools index $OUTPUTBAM
echo "Done!"