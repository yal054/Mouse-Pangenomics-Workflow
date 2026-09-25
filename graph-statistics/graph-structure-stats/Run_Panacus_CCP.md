# Panacus graph statistics: CC Pangenome

Computes pangenome traversal statistics (node coverage histogram, pangenome
growth, node degree distribution) on the CC Pangenome graph with
[Panacus](https://github.com/marschall-lab/panacus).

## Inputs

| Variable | Description |
|---|---|
| `GRAPH_GFA` | CC Pangenome graph in GFA format (`founder.plus_allCC.gfa`) |
| `WORKDIR` | Output directory |
| `PANACUS` | Path to the `panacus` binary, v0.4.1 |

```bash
GRAPH_GFA=/path/to/founder.plus_allCC.gfa
WORKDIR=/path/to/graph_descriptive_statistics
PANACUS=/path/to/panacus-0.4.1/bin/panacus
```

## Outputs

`report.html`, containing the coverage histogram, growth curves and node
distribution tables.

## 1. Set up the working directory

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"
ln -s "$GRAPH_GFA" .
```

## 2. Write the Panacus report configuration

`report.yaml`:

```yaml
- graph: founder.plus_allCC.gfa
  analyses:
    - !Hist
      count_type: All
    - !Growth
      coverage: 1,5,10,20,30,40
    - !NodeDistribution
```

## 3. Run Panacus

```bash
# Resources used: 20 CPUs, 256 GB RAM, ~3 h wall time on the CC Pangenome
cd "$WORKDIR"
"$PANACUS" report report.yaml > report.html
```

## Downstream table extraction

The summary tables plotted in `Visualize_Panacus_Results.Rmd` were extracted
from `report.html` by hand.
