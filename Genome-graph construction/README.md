Template scripts and files used to create all graphs (DMP, CCP, LT x3, F1 x45) using the Minigraph-Cactus Pangenome Pipeline

`launch-minigraph-cactus-graph-construction.sh`: driver script that launches a WDL workflow implementing the Minigraph-Cactus Pangenome Pipeline
- `-Dconfig.file=cromwell.config`: Configures Cromwell for a particular compute environment
- `-i mcgb-inputs.json`: See below
- `mcgb.wdl`: [Available on Github](https://github.com/twlab/cig-pipelines/blob/main/wdl/pipelines/pangenome/mcgb.wdl)

`mcgb-inputs.json`: contains inputs to the WDL workflow, including resource requests and graph configuration
- `pangenome_mcgb.name`: prefix to be used for all graphs and indices output by the pipeline
- `pangenome_mcgb.ref`: one or more (space separated) assembly labels to be set as reference path(s) within the output graphs; must match labels in the seqfile (see below)
- `pangenome_mcgb.seqfile`: path to a seqfile specifying assemblies from which to build the graph (see below)
- `pangenome_mcgb.graph_types`: which classes of graph to retain in the final output; by default, only clipped
- `pangenome_mcgb.run_panacus`: whether or not to automatically run Panacus on the output graphs produced by M-C; defaults to true, but set to false during this analysis in favor of manually running it due to technical difficulties
- `pangenome_mcgb.docker`: Docker image used to run each of the five M-C steps (each implemented as a WDL task)
- `pangenome_mcgb.cpu`: number of CPUs to request per task
- `pangenome_mcgb.memory`: amount of RAM in GB to request per task

`DMP-seqfile.tsv`: 2 column tab separated list of assembly labels and paths; the provided file is the DMP seqfile, since it is the most complete, containing all 95 assemblies used in this study
- CCP graph uses the first 84 lines/assemblies from this file
- LT graphs (3 total) each use the same list as the CCP graph, except for one pair from the following list per graph: CC004×CC017, CC015×CC040, CC027×CC036
- F1 graphs (45 total) each contain mm10/GRCm38 and GRCm39, as well as a pair of RI or Founder assemblies:
  - RI pairs: `CC001×CC074, CC002×CC005, CC003×CC062, CC004×CC017, CC006×CC060, CC007×CC049, CC008×CC010, CC009×CC018, CC011×CC078, CC012×CC038, CC015×CC040, CC021×CC075, CC023×CC024, CC025×CC028, CC027×CC036, CC033×CC043, CC039×CC061, CC044×CC045, CC046×CC068, and CC057×CC058`
  - Founder pairs: `129S1_SvImJ×CAST_EiJ, NOD_ShiLtJ×WSB_EiJ, NZO_HlLtJ×NOD_ShiLtJ, PWK_PhJ×CAST_EiJ, and WSB_EiJ×CAST_EiJ`

`panacus.sh`: used to calculate graph statistics
- `graph.full.gfa.gz`: the graph from which to generate statistics
- `graph.full.panacus-hist.tsv`: output file, suitable for representation as a histogram

`build-personalized-pangenome-haplotype-indices.sh`: script used to manually generate haplotype indices, used to create personalized graphs for large graphs prior to alignment
- `vg gbwt`: used to create an r-index, a prerequesite for the haplotype index
  - `-p`: report progress
  - `--num-threads 30`: set number of threads to use
  - `-r graph.ri`: suggested format for the r-index name; <graph-prefix>.ri
  - `-Z graph.gbz`: input graph file
- `vg haplotypes`: used to create a haplotype index for personalization
  - `-H graph.hapl`: suggested format for the haplotype index name; <graph-prefix>.hapl
  - `graph.gbz`: input graph file; implicitly uses the r-index, assuming the above naming convention was followed
