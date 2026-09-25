# Genome-graph construction

Descriptive statistics of the pangenome graph structure.

The graphs were built with Minigraph-Cactus by co-authors and are inputs here.

## Graph structure statistics (`graph-structure-stats/`)

`vg stats` gives node, edge and degree counts; Panacus gives traversal
statistics across haplotypes.

- `Prepare_stats_DMP_and_founder.md`: assemble the `vg stats` outputs for the
  Draft Mouse Pangenome and the Founder Pangenome
- `Visualize_all_graph_stats.Rmd`: node and edge counts, plus the node degree
  distribution, for both graphs
- `Run_Panacus_CCP.md`: run Panacus on the CC Pangenome to produce the coverage
  histogram, pangenome growth curves, and node distribution
- `Visualize_Panacus_Results.Rmd`: the segment-sharing distribution (the
  fraction of nodes traversed by a given number of haplotypes), plus growth
  curves by node, edge and bp

### Reference values

From Supplementary Note 1, for checking a re-run.

| | Founder Pangenome | Draft Mouse Pangenome |
|---|---|---|
| nodes | 155,931,308 | 176,152,951 |
| edges | 213,332,699 | 242,034,955 |
| nodes with < 3 edges | 62.3% | 61.5% |
| segments shared by > 90% of assemblies | 26.7% | 25.0% |
| segments shared by < 5% of assemblies | 13.1% | 9.5% |

The summary tables that `Visualize_Panacus_Results.Rmd` plots were extracted
by hand from Panacus's `report.html` (see `Run_Panacus_CCP.md`).
