# Per-bubble variant statistics: Founder Pangenome

Classifies every alternative allele in the deconstructed Founder Pangenome as
SNV, INDEL, MNV or COMPOSITE, and records the `N` content of each allele.

The DMP counterpart is
`Calculate_per_bubble_stats_for_the_DMP_graph_from_deconstructed_graph.md`; the
two are combined for the published panel by
`Calculate_per_bubble_stats_for__plot_Founder_and_DMP_together_for_panel.Rmd`.

See [variant_classification.md](variant_classification.md) for what the
classification means and how `N` runs are handled.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `VCF` | deconstructed Founder Pangenome VCF |

```bash
WORKDIR=/path/to/per_bubble_stats_founder
VCF=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.vcf.gz
```

The deconstructed VCF was produced upstream.

## Outputs

| File | Contents |
|---|---|
| `*.vcf.stats` | `bcftools stats` summary |
| `*.vcf.tsv` | per-site classification |
| `*.vcf.exploded.tsv` | one row per ALT allele |

## 1. Index and summarize the VCF

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)
tabix -p vcf "$VCF"

eval $( spack load --sh bcftools/6unbpgv )   # bcftools, version not recorded (build hash 6unbpgv)
bcftools stats "$VCF" > "$(basename "${VCF%.gz}").stats"
```

The `bcftools stats` output is visualized by
`Visualize_deconstructed_Founder_stats.Rmd` (Ts/Tv, allele frequency, indel
length and substitution types).

## 2. Classify alleles per site

```bash
cd "$WORKDIR"

# python 3.8.12
eval $( spack load --sh /pudl6n3 )

python Assign_Variant_Classes_Per_Bubble.py "$VCF" \
  -o Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.vcf.tsv
```

## 3. Explode multi-ALT sites

One row per alternative allele, so classes can be counted per allele.

```bash
cd "$WORKDIR"

eval $( spack load --sh /pudl6n3 )   # python 3.8.12 (build hash pudl6n3)

python Split_Multi_ALT_Per_Bubble.py \
  Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.vcf.tsv \
  --cpus 16 \
  -o Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.vcf.exploded.tsv
```

## Downstream

`Calculate_per_bubble_stats_for_the_Founder_graph_from_deconstructed_graph.Rmd`
reads both tables: the per-site table for site counts, ALTs per site and
per-site class composition; the exploded table for allele counts by class and
their `N` content.
