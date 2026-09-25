# Per-bubble variant statistics: Draft Mouse Pangenome

Classifies every alternative allele in the deconstructed Draft Mouse Pangenome
as SNV, INDEL, MNV or COMPOSITE, and records the `N` content of each allele.

Identical in procedure to
`Calculate_per_bubble_stats_for_the_Founder_graph_from_deconstructed_graph.md`;
only the input graph differs. The two are combined for the published panel by
`Calculate_per_bubble_stats_for__plot_Founder_and_DMP_together_for_panel.Rmd`.

See [variant_classification.md](variant_classification.md) for what the
classification means and how `N` runs are handled.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `VCF` | deconstructed DMP VCF (normalized) |

```bash
WORKDIR=/path/to/per_bubble_stats_dmp
VCF=/path/to/DMP.full.vcf.gz
```

The DMP is the Minigraph-Cactus graph over all 95 assemblies; its deconstructed
VCF was produced upstream.

## Outputs

| File | Contents |
|---|---|
| `DMP.full.vcf.stats` | `bcftools stats` summary |
| `DMP.full.vcf.tsv` | per-site classification |
| `DMP.full.vcf.exploded.tsv` | one row per ALT allele |

## 1. Index and summarize the VCF

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)
tabix -p vcf "$VCF"

eval $( spack load --sh bcftools/6unbpgv )   # bcftools, version not recorded (build hash 6unbpgv)
bcftools stats "$VCF" > DMP.full.vcf.stats
```

Visualized by `Visualize_deconstructed_DMP_stats.Rmd`.

## 2. Classify alleles per site

```bash
cd "$WORKDIR"

# python 3.8.12
eval $( spack load --sh /pudl6n3 )

python Assign_Variant_Classes_Per_Bubble.py "$VCF" -o DMP.full.vcf.tsv
```

## 3. Explode multi-ALT sites

```bash
cd "$WORKDIR"

eval $( spack load --sh /pudl6n3 )   # python 3.8.12 (build hash pudl6n3)

python Split_Multi_ALT_Per_Bubble.py DMP.full.vcf.tsv \
  --cpus 16 -o DMP.full.vcf.exploded.tsv
```

## Downstream

`Calculate_per_bubble_stats_for_the_DMP_graph_from_deconstructed_graph.Rmd`
reads both tables, as for the Founder Pangenome.
