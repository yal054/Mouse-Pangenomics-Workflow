#!/bin/bash
#BSUB -a 'docker(zhengxu32/pan_qc:1.0.10)'
#BSUB -q general
#BSUB -g /xu.z1/default
#BSUB -G compute-yeli
#BSUB -R 'select[mem>8G]'
#BSUB -R 'rusage[mem=8G]'
#BSUB -R 'span[hosts=1]'
#BSUB -M 8G
#BSUB -n 2
#BSUB -oo /storage1/fs1/hprc/Active/xu.z1/logs/Simulation_-%J.log
#BSUB -ee /storage1/fs1/hprc/Active/xu.z1/logs/Simulation_-%J.err

# ENVs
LSF_DOCKER_PRESERVE_ENVIRONMENT=false
LSF_DOCKER_VOLUMES="/scratch1/fs1/hprc:/scratch1/fs1/hprc /storage1/fs1/hprc:/storage1/fs1/hprc"

set -ex


#/storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC013_genome.fa
#/storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC016_genome.fa
#/storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC019_genome.fa
#/storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC020_genome.fa
#/storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC022_genome.fa
#/storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC026_genome.fa
#/storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC029_genome.fa

bash /storage1/fs1/hprc/Active/xu.z1/zheng_General_Code/Mouse_Pangenome_Stage_2/Simulation_Pipeline.sh \
-n 2 \
-o /storage1/fs1/hprc/Active/xu.z1/Mouse_Pangenome_Stage_2_Output/Simulation_output \
-g /storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC013_genome.fa \
-d 100

bash /storage1/fs1/hprc/Active/xu.z1/zheng_General_Code/Mouse_Pangenome_Stage_2/Simulation_Pipeline.sh \
-n 2 \
-o /storage1/fs1/hprc/Active/xu.z1/Mouse_Pangenome_Stage_2_Output/Simulation_output \
-g /storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC016_genome.fa \
-d 100

bash /storage1/fs1/hprc/Active/xu.z1/zheng_General_Code/Mouse_Pangenome_Stage_2/Simulation_Pipeline.sh \
-n 2 \
-o /storage1/fs1/hprc/Active/xu.z1/Mouse_Pangenome_Stage_2_Output/Simulation_output \
-g /storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC019_genome.fa \
-d 100

bash /storage1/fs1/hprc/Active/xu.z1/zheng_General_Code/Mouse_Pangenome_Stage_2/Simulation_Pipeline.sh \
-n 2 \
-o /storage1/fs1/hprc/Active/xu.z1/Mouse_Pangenome_Stage_2_Output/Simulation_output \
-g /storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC020_genome.fa \
-d 100

bash /storage1/fs1/hprc/Active/xu.z1/zheng_General_Code/Mouse_Pangenome_Stage_2/Simulation_Pipeline.sh \
-n 2 \
-o /storage1/fs1/hprc/Active/xu.z1/Mouse_Pangenome_Stage_2_Output/Simulation_output \
-g /storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC022_genome.fa \
-d 100

bash /storage1/fs1/hprc/Active/xu.z1/zheng_General_Code/Mouse_Pangenome_Stage_2/Simulation_Pipeline.sh \
-n 2 \
-o /storage1/fs1/hprc/Active/xu.z1/Mouse_Pangenome_Stage_2_Output/Simulation_output \
-g /storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC026_genome.fa \
-d 100

bash /storage1/fs1/hprc/Active/xu.z1/zheng_General_Code/Mouse_Pangenome_Stage_2/Simulation_Pipeline.sh \
-n 2 \
-o /storage1/fs1/hprc/Active/xu.z1/Mouse_Pangenome_Stage_2_Output/Simulation_output \
-g /storage1/fs1/hprc/Active/shared/yang_li_mouse_graphs/new/CC029_genome.fa \
-d 100






