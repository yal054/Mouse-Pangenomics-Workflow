# Build and deconstruct the combined DO graph

Builds a combined GBZ from the merged DO GBWT, deconstructs it to a VCF in mm10
coordinates, and normalizes the contig names.

The output VCF is the input to
`Compare_personalized_paths_between_coverage_levels.md`, whose summary tables
feed `Per_site_concordance_rate.Rmd`. Follows `Merge_DO_combined_into_full_graph.md`,
which produces `founder.plus_allDO.gbwt` from the low- and high-coverage arms.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | directory holding the merged GBWT |
| `FULL_GBZ` | founder pangenome graph, GBZ |
| `VG` | path to the `vg` binary |

```bash
WORKDIR=/path/to/Merge_DO_combined_into_full_graph/02_merge
FULL_GBZ=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.gbz
VG=/path/to/vg
```

## Outputs

`founder.plus_allDO.deconstruct.mm10.noprefix.vcf.gz` and its tabix index.

## 1. Build the combined GBZ

```bash
cd "$WORKDIR"

# Resources used: 20 threads
"$VG" gbwt --num-threads 20 \
  -x "$FULL_GBZ" founder.plus_allDO.gbwt \
  --gbz-format -g founder.plus_allDO.gbz
```

## 2. Deconstruct to VCF

```bash
cd "$WORKDIR"

"$VG" deconstruct --path-prefix mm10 -t 20 --verbose \
  founder.plus_allDO.gbz > founder.plus_allDO.deconstruct.mm10.vcf
```

## 3. Strip the path prefix from contig names

`vg deconstruct` emits PanSN-style contig names (`mm10#0#chr1`), which most
downstream tools will not match against a plain mm10 annotation. Build a
rename map from the header and apply it.

```bash
cd "$WORKDIR"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh bcftools/6unbpgv )   # bcftools, version not recorded (build hash 6unbpgv)

VCF=founder.plus_allDO.deconstruct.mm10.vcf

bcftools view -h "$VCF" \
  | grep '^##contig=<ID=mm10#0#' \
  | sed -E 's/^##contig=<ID=([^,>]+).*/\1/' \
  | awk 'BEGIN{FS=OFS="\t"} {old=$1; new=$1; sub(/^mm10#0#/,"",new); print old, new}' \
  > rename_chrs.tsv

bcftools annotate --rename-chrs rename_chrs.tsv \
  -Ov -o founder.plus_allDO.deconstruct.mm10.noprefix.vcf \
  "$VCF"
```

Confirm the rename took, in both the header and the records:

```bash
cd "$WORKDIR"
grep '^##contig=<ID=' founder.plus_allDO.deconstruct.mm10.noprefix.vcf | head
grep -v '^#' founder.plus_allDO.deconstruct.mm10.noprefix.vcf | head -n 3 | cut -f1
```

## 4. Compress and index

```bash
cd "$WORKDIR"

eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)

bgzip -@ 12 founder.plus_allDO.deconstruct.mm10.noprefix.vcf
tabix -p vcf founder.plus_allDO.deconstruct.mm10.noprefix.vcf.gz
```

The prefixed VCF and the rename map are intermediates and can be removed once
the indexed output exists.
