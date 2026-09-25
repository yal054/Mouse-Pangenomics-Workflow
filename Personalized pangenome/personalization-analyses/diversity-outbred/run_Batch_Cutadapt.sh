#!/bin/bash
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
#SBATCH -N 1
#SBATCH -J cutadapt

####SBATCH --array=1-10%10   # This will create 40 tasks numbered 1-40 and allow 10 concurrent jobs to run

# [Alignment parameters lookup file]
read READ1 READ2 OUTPUT1 OUTPUT2 TRIMLOG < <( sed -n ${SLURM_ARRAY_TASK_ID}p $1 )
## COUNT TAKES ON VALUE OF TRUE OR FALSE

adapter_1="CTGTCTCTTATACACATCT"
adapter_2="CTGTCTCTTATACACATCT"

echo "Loading software..."
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh py-cutadapt@2.10 )


echo "Input files: "$READ1" "$READ2
echo "Output files: "$OUTPUT1" "$OUTPUT2
echo "Trim log: "$TRIMLOG

echo "Starting Trim..."
cutadapt -a $adapter_1 -A $adapter_2 --quality-cutoff=15,10 --minimum-length=36 -o $OUTPUT1 -p $OUTPUT2 $READ1 $READ2 > $TRIMLOG
echo " ...Complete!"
