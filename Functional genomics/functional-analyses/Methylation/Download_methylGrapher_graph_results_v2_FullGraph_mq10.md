# Retrieve methylGrapher graph methylation calls

Collects the per-library `.graph.methyl` calls produced by methylGrapher
against the full founder pangenome, at MapQ > 10.

These are the inputs to `Surject_methylation_calls_v2_FullGraph_mq10.md`.

## Relaxed settings

Manual review of the calls from methylGrapher's default settings showed that
most differences against the linear reference are CpG gain and loss through
deamination and through structural variation, frequently at transposable
elements. The default methylGrapher settings are conservative and discard
reads falling in non-reference insertions, recovering them only at the flanks.

The settings were relaxed to recover methylated sites inside non-reference
sequence, with a MapQ > 10 filter applied in their place.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | output directory |
| `MG_URL` | base URL of the methylGrapher results |

```bash
WORKDIR=/path/to/WGBS/methylGrapher_v2_FullGraph_mq10
MG_URL=https://<host>/projects/mouse_pg/wgbs_ng_r1/methylgrapher_full
```

The calls were generated upstream by a co-author.

## Libraries

Two merged sets and eight individual libraries:

| Name | Contents |
|---|---|
| `merged_bl6` | merged C57BL/6J |
| `merged_cast` | merged CAST/EiJ |
| `SRX2175958` … `SRX2175965` | individual libraries |

## Download

Each library directory holds a `mq10.graph.methyl`, renamed on retrieval to
carry the library name.

```bash
mkdir -p "$WORKDIR/GraphMethyl"
cd "$WORKDIR"

SAMPLES="merged_bl6 merged_cast SRX2175958 SRX2175959 SRX2175960 SRX2175961 \
SRX2175962 SRX2175963 SRX2175964 SRX2175965"

for s in $SAMPLES; do
    wget -O "GraphMethyl/${s}.graph.methyl" "$MG_URL/${s}/mq10.graph.methyl"
done
```

## Verify

```bash
cd "$WORKDIR/GraphMethyl"
ls -1 *.graph.methyl | wc -l    # expect 10
head -2 merged_cast.graph.methyl
```
