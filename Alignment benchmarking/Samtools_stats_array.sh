#!/bin/bash

# Define the input and output directories for each folder
input_dirs=(
  "/storage2/fs1/epigenome/Active/johnegarza/MPRC/Founder_real_alignments/linear/refv2"
)

output_dirs=(
  "/storage1/fs1/hprc/Active/xu.z1/Mouse_Pangenome_Stage_2_Output/Counting_output/linear_samtools_flagstat/real_refv2"
)

# Loop over each pair of input and output directories
for idx in "${!input_dirs[@]}"; do
    BAM_FILE_DIR="${input_dirs[idx]}"
    OUTPUT_DIR="${output_dirs[idx]}"

    # Create the output and job submission script directories if they don't exist
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR/job_submission_scripts"

    # Loop over each *.bam file in the current input directory
    for bam in "$BAM_FILE_DIR"/*.bam; do
        if [ -f "$bam" ]; then
            # Get sample name (strip .bam extension)
            sample=$(basename "$bam")
            sample=${sample%.bam}

            # Define the job submission script path
            job_script="${OUTPUT_DIR}/job_submission_scripts/${sample}_samtools_flagstat.bsub"

            # Create the BSUB job script
            cat > "$job_script" <<EOF
#!/bin/bash

#BSUB -q general
#BSUB -G compute-yeli
#BSUB -g /xu.z1/array
#BSUB -a 'docker(zhengxu32/pan_qc:1.0.10)'
#BSUB -R 'select[mem>16G]'
#BSUB -R 'rusage[mem=16G]'
#BSUB -R 'span[hosts=1]'
#BSUB -M 16G
#BSUB -n 2
#BSUB -oo /storage1/fs1/hprc/Active/xu.z1/logs/samtools_stats_array-%J.log
#BSUB -e /storage1/fs1/hprc/Active/xu.z1/logs/samtools_stats_array-%J.err

set -ex

# Change to samtools stats if needed
# If it is changed from flagstat to stats, please change the output file name accordingly
samtools flagstat -@ 2 "$bam" > "$OUTPUT_DIR"/"${sample}.output.samtools_flagstat.txt"
EOF

            # Make the job script executable
            chmod +x "$job_script"

            #Touch the output file to ensure it exists before submission and avoid permissions issues
            touch "$OUTPUT_DIR"/"${sample}.output.samtools_flagstat.txt"

            #Give permission to the output file
            chmod 777 "$OUTPUT_DIR"/"${sample}.output.samtools_flagstat.txt"

            # Submit the job via LSF
            echo "Submitting job for sample: ${sample} from folder: ${BAM_FILE_DIR}"
            bsub < "$job_script"
        fi
    done
done