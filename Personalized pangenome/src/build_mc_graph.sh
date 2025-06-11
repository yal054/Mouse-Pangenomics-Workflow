#!/bin/bash




# module load singularity
# singularity run --bind /scratch/wzhang/:/scratch/wzhang/ /scratch/wzhang/projects/mouse_pg/graph_building/cactus_v2.9.3.sif

# singularity exec --bind /scratch/wzhang/:/scratch/wzhang/ /scratch/wzhang/projects/mouse_pg/graph_building/cactus_v2.9.3.sif bash /scratch/wzhang/projects/mouse_pg/graph_building/gt4/run.sh quad mm10 /scratch/wzhang/projects/mouse_pg/graph_building/gt1/ /scratch/wzhang/projects/mouse_pg/graph_building/gt1/seqfile.tsv 50 180G


# 35 threads and 120G request memory on wangcluster
# but let maxMemory 400g

cpu=50
memory=180G


name=quad
ref=mm10
wd=/scratch/wzhang/projects/mouse_pg/graph_building/gt1/
seqfile_input=/scratch/wzhang/projects/mouse_pg/graph_building/gt1/seqfile.tsv


name=$1
ref=$2
wd=$3
seqfile_input=$4

cpu=$5
memory=$6



# TMP variables
jobstore="jobstore"
sv_gfa="$name.sv.gfa"

paf="$name.paf"
fasta="$name.sv.gfa.fasta"

seqfile="$wd/seqfile.tsv"




export OMP_NUM_THREADS=$cpu

mkdir -p $wd
cd $wd

cp $seqfile_input $seqfile

# 1 run_cactus_minigraph
cactus-minigraph $jobstore $seqfile $sv_gfa --reference $ref --maxCores $cpu --maxMemory $memory --defaultDisk 100G --binariesMode local


# 2 run_cactus_graphmap
cactus-graphmap $jobstore $seqfile $sv_gfa $paf --outputFasta $fasta --reference $ref --maxCores $cpu --maxMemory $memory --defaultDisk 100G --binariesMode local


# 3 run_cactus_graphmap_split
# sed -i 's,_MINIGRAPH_\t.*,_MINIGRAPH_\t~{minigraph_fasta},' $seqfile
cactus-graphmap-split $jobstore $seqfile $sv_gfa $paf --outDir chroms --reference $ref --maxCores $cpu --maxMemory $memory --defaultDisk 100G --binariesMode local


# 4 run_cactus_align
find chroms/seqfiles/ -type f | while read -r sf; do sed -i 's,file:///.*/execution/,,' $sf; done
cactus-align $jobstore chroms/chromfile.txt alignments --batch --pangenome --reference $ref --outVG --maxCores $cpu --maxMemory $memory --defaultDisk 100G --binariesMode local



# 5 run_cactus_graphmap_join
cactus-graphmap-join $jobstore --vg alignments/*.vg --hal alignments/*.hal --outDir . --outName $name --reference $ref --vcf full --gfa full --giraffe full --maxCores $cpu --maxMemory $memory --defaultDisk 100G --binariesMode local
cactus-graphmap-join $jobstore --vg alignments/*.vg --hal alignments/*.hal --outDir . --outName $name --reference $ref --vcf clip --gfa clip --giraffe clip --maxCores $cpu --maxMemory $memory --defaultDisk 100G --binariesMode local







