# Alignment Benchmarking Pipelines

Pipelines for computing alignment metrics from BAM and GAM files.

## Note

All job submission scripts are designed for the Washington University RIS computing service with the IBM LSF system. Therefore, there is typically a pipeline that performs the actual work and another individual pipeline that specifies resources, computing nodes, Docker images, etc., according to RIS requirements to set up the environment and execute the actual pipeline. This may not be the usual practice across other platforms. Please modify the scripts based on your specific computing platform before proceeding.

## Read Simulation

- Actual pipeline: `Simulation_Pipeline.sh`
- RIS job submission script: `Kick_Simulation.sh`

This pipeline simulates WGS libraries using wgsim based on given parameters and input genomes.

## Samtools-based BAM File Statistics Summary

- Actual pipeline and RIS job submission script: `Samtools_stats_array.sh`

This pipeline performs samtools stats or samtools flagstat for input BAM files and writes the output to text files.

**Note:** The current version performs samtools flagstat (which is necessary for downstream counting). If you would like to perform samtools stats instead, please modify 'flagstat' to 'stats' as indicated in the code comments. Since this is a simple step, the pipeline and job submission process are integrated together.

## Vg-based GAM File Statistics Summary

vg stats is employed to perform statistics summary for GAM files. This functionality is integrated into the graph alignment pipeline. Please refer to the WGS alignment section.

## Counting Alignment QC Values

- Actual pipeline: `Custom_Counting.sh`
- RIS job submission script: `Kick_Custom_Counting_Shell.sh`

This pipeline creates final stats reports for each sample.

## Results Collection

After counting alignment QC values for each sample, a result collection script is employed to create a TSV format summary for samples within each group. Here, we use the 'Real WGS library aligned to GRCm38 reference' group as an example: `Stats_script_real_refv2.sh`

## Plotting

After obtaining TSV results from every group, an R script is employed for plotting: `Stats_Plotting.R`

