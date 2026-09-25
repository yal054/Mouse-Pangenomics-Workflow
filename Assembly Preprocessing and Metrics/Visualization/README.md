# Assembly Preprocessing and Metrics

Quality metrics for the assemblies that went into the pangenome graphs.

`Visualize_Assembly_QC_for_the_max_graph_assemblies.Rmd` plots total assembly
length, gap content, and BUSCO complete-gene percentage across the 23 assemblies
from 19 strains: the 8 CC founders plus 11 additional classical and
wild-derived strains, with C57BL/6J and CAST/EiJ contributing 4 and 2 assemblies
respectively.

## Inputs

BUSCO `short_summary` text files, one per assembly, plus an assembly statistics
table and a strain colour key. The Rmd reads the BUSCO files from a directory of
`*_busco.txt`; set the paths in the params block at the top.

## Notes on the grouping logic

The Rmd relabels strains in several steps. It collapses the RI
variants into a single "RI" group, normalizes strain names (including a
correction of `NZO/HILtJ` to `NZO/HlLtJ`), and folds assembly-version suffixes
into one "Founder" group. This logic follows the naming of this assembly
collection; changing it changes which group an assembly lands in.

A list of GCA accessions is excluded before plotting: assemblies that were
collected but not used in the graphs.
