# Retrieve Bismark methylation calls

Collects the Bismark-aligned WGBS methylation calls used as the linear-reference
comparison against methylGrapher.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | output directory |
| `BISMARK_URL` | base URL of the Bismark results |

```bash
WORKDIR=/path/to/WGBS/Bismark_data
BISMARK_URL=https://<host>/projects/mouse_pg/wgbs_ng_r1/bismark
```

Two alignment sets are served, one per linear reference:

| Set | Path | Reference |
|---|---|---|
| `c57` | `$BISMARK_URL/c57/` | C57BL/6J mT2T |
| `cast` | `$BISMARK_URL/cast/` | CAST/EiJ T2T |

Each sample directory holds a `track.cpg.methylc.gz`; only those are needed.
The calls were generated upstream by a co-author.

## Download

```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"

wget \
  --recursive \
  --no-parent \
  --level=2 \
  --no-host-directories \
  --cut-dirs=5 \
  --reject "index.html*" \
  --accept "track.cpg.methylc.gz" \
  "$BISMARK_URL/c57/" \
  "$BISMARK_URL/cast/"
```

`--cut-dirs=5` strips the served prefix so the local tree is
`c57/<sample>/track.cpg.methylc.gz`. Adjust it if `BISMARK_URL` has a different
depth.

## Verify

```bash
cd "$WORKDIR"
find . -name 'track.cpg.methylc.gz' | wc -l
```
