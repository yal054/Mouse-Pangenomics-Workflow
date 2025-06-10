#!/bin/bash

# window size for QC
window_size=100000

# list your CC samples here
samples=(
  CC002
  CC005
  CC007
  CC049
  CC011
  CC078
  CC024
  CC023
  CC043
  CC033
  CC046
  CC068
  CC060
  CC006
  CC075
  CC021
  CC001
  CC074
  CC003
  CC062
  CC008
  CC010
  CC012
  CC038
  CC018
  CC009
  CC025
  CC028
  CC045
  CC044
  CC057
  CC058
  CC061
  CC039
)

# where to write your sub-job scripts
JOBDIR="/storage2/fs1/epigenome/Active/xu.z1/positional_qc/job_submission_scripts"
mkdir -p "$JOBDIR"

for cc in "${samples[@]}"; do
    # define inputs/outputs per sample
    input_file="/storage2/fs1/epigenome/Active/xu.z1/positional_qc/RI_simulated_alignments/${cc}/GRCm38v2-ref.${cc}-query_positional_qc.txt"
    output_file="/storage2/fs1/epigenome/Active/xu.z1/positional_qc/RI_simulated_alignments/${cc}/GRCm38v2-ref.${cc}-query_positional_qc.tsv"
    job_script="${JOBDIR}/GRCm38v2_${cc}_Positional_QC.bsub"

    # write per-sample BSUB script
    cat > "$job_script" <<EOF
#!/bin/bash
#BSUB -a 'docker(zhengxu32/pan_qc:1.0.12)'
#BSUB -q general
#BSUB -g /xu.z1/default
#BSUB -G compute-yeli
#BSUB -R 'select[mem>24G]'
#BSUB -R 'rusage[mem=24G]'
#BSUB -R 'span[hosts=1]'
#BSUB -M 24G
#BSUB -n 8
#BSUB -oo /storage2/fs1/hprc/Active/xu.z1/logs/Positional_QC_${cc}_%J.log
#BSUB -e /storage2/fs1/hprc/Active/xu.z1/logs/Positional_QC_${cc}_%J.err

export LSF_DOCKER_PRESERVE_ENVIRONMENT=false
export LSF_DOCKER_VOLUMES="/home/xu.z1:/home/xu.z1 /scratch1/fs1/hprc:/scratch1/fs1/hprc /storage2/fs1/hprc:/storage2/fs1/hprc"

set -ex

bash /storage2/fs1/hprc/Active/xu.z1/zheng_General_Code/Mouse_Pangenome_Stage_2/Binned_QC_Stats.sh \\
    -i "$input_file" \\
    -o "$output_file" \\
    -w "$window_size"
EOF

    chmod +x "$job_script"

    echo "Submitting ${cc}..."
    bsub < "$job_script"
done