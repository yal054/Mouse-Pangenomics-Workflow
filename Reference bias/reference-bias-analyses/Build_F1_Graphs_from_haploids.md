# Build in-silico F1 graphs from haploid RI assemblies

Combines pairs of haploid RI traversals into diploid F1 graphs and deconstructs
them to VCFs, giving the heterozygous-site truth set for the reference-bias
analysis.

Prerequisite for `Analyze_Reference_Bias_Pileups.md`.

## Why

Reference bias is measured at heterozygous sites. For a simulated F1 we must
know where those sites are, which means knowing exactly where the two parental
haploid assemblies differ. Combining the two haploid GBWTs for a pair and
deconstructing the result gives precisely that set.

Reads are simulated from each haploid assembly and mixed 1:1 to form the F1
dataset; the deconstructed VCF says which sites should be heterozygous.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `HAP_ROOT` | haploid personalization results, `<line>/sampled.gbz` |
| `FULL_GBZ` | founder pangenome graph, GBZ |
| `GBWT_BATCH` | `run_make_and_rename_recombinant_only_gbwt.sh` |
| `CHUNK_BATCH` | `run_merge_gbwt_chunk.sh` |
| `GBZ_BATCH` | `run_GBZ_from_GBWT.sh` |
| `VG` | path to the `vg` binary |

```bash
WORKDIR=/path/to/Reference_Bias/F1_variant_generation
HAP_ROOT=/path/to/personalization_haploid/full
FULL_GBZ=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.gbz
GBWT_BATCH="../../Personalized pangenome/personalization-analyses/run_make_and_rename_recombinant_only_gbwt.sh"
CHUNK_BATCH="../../Personalized pangenome/personalization-analyses/run_merge_gbwt_chunk.sh"
GBZ_BATCH="../../Personalized pangenome/personalization-analyses/run_GBZ_from_GBWT.sh"
VG=/path/to/vg
```

> These are the haploid-mode personalization results (`vg haplotypes` run in
> haploid mode, one traversal per line), not the diploid results used
> elsewhere in this repository.

## The 20 F1 pairs

| | | | | | |
|---|---|---|---|---|---|
| CC001 × CC074 | CC002 × CC005 | CC003 × CC062 | CC004 × CC017 | CC006 × CC060 |
| CC007 × CC011 | CC008 × CC010 | CC009 × CC018 | CC016 × CC020 | CC012 × CC038 |
| CC015 × CC040 | CC021 × CC075 | CC023 × CC024 | CC025 × CC028 | CC027 × CC036 |
| CC033 × CC043 | CC039 × CC061 | CC044 × CC045 | CC046 × CC068 | CC057 × CC058 |

## Outputs

`GBZ_Deconstructed_VCFs/<A>x<B>.vcf.gz` and indices, 20 F1 variant sets.

## 1. Stage the haploid graphs

```bash
mkdir -p "$WORKDIR/full_haploid_graphs"
cd "$WORKDIR/full_haploid_graphs"

for i in "$HAP_ROOT"/*/sampled.gbz; do
  SAMPLE=$(basename "$(dirname "$i")")
  ln -s "$i" "${SAMPLE}.gbz"
done
```

## 2. Extract a renamed haploid GBWT per line

`run_make_and_rename_recombinant_only_gbwt.sh` reads one line per RI line from
`params.make_and_rename_recombinant_only_gbwt.tsv`, tab-separated:
`GBZ  SAMPLE  OUTD  REFS_TO_DROP`
`GBZ` is the staged `full_haploid_graphs/<line>.gbz`, `SAMPLE` is `<line>`,
`OUTD` is `$WORKDIR`, and `REFS_TO_DROP` is the comma-separated list of
reference samples removed from each haploid GBWT,
`C57BL_6_T2T_Yu,GRCm39,mm10`. The output is `<line>.gbwt`. 40 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-40%10 "$GBWT_BATCH" \
  params.make_and_rename_recombinant_only_gbwt.tsv
```

Confirm a line's paths were renamed as expected:

```bash
cd "$WORKDIR"
"$VG" gbwt --num-threads 16 -S -L CC001.gbwt
```

## 3. Extract the founder reference paths

The F1 graphs need reference paths present, or deconstruction has nothing to
anchor against.

> All eight founders are retained rather than GRCm38 alone (nine paths, since
> CAST/EiJ has two assemblies). GRCm38 is not the
> graph's primary reference, and deconstructing against it alone risks failing
> on regions where it is not represented.

```bash
cd "$WORKDIR"

"$VG" gbwt --num-threads 16 -o Founder.gbwt -Z "$FULL_GBZ"

"$VG" gbwt --num-threads 16 \
  -o References.gbwt \
  -R 129S1_SvImJ \
  -R A_J \
  -R C57BL_6J_T2T_Keane \
  -R CAST_EiJ \
  -R CAST_EiJ_T2T_Keane \
  -R NOD_ShiLtJ \
  -R NZO_HlLtJ \
  -R PWK_PhJ \
  -R WSB_EiJ \
  Founder.gbwt

"$VG" gbwt --num-threads 16 -S -L References.gbwt
```

## 4. Merge each pair into an F1 GBWT

`run_merge_gbwt_chunk.sh` takes a file listing the GBWTs to merge. Each pair
in the table above has one such list, `<A>x<B>.params`, with one GBWT per
line:
`<A>.gbwt`
`<B>.gbwt`
`References.gbwt`

`run_merge_gbwt_chunk.sh` reads one line per pair from
`GBWT_Pairs_Parameters.txt`:
`CHUNK_LIST`
`CHUNK_LIST` is the path to that pair's `<A>x<B>.params`. 20 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-20%10 "$CHUNK_BATCH" GBWT_Pairs_Parameters.txt

# the batch script prefixes its output; restore the pair name
for f in chunk_*.params.gbwt; do
    new="${f#chunk_}"; new="${new%.params.gbwt}.gbwt"
    mv "$f" "$new"
done
```

## 5. Build a GBZ per pair

`run_GBZ_from_GBWT.sh` reads one line per pair from
`GBZ_construction_parameters.txt`, tab-separated:
`INPUT_GRAPH  GBWT  OUTPUT`
`INPUT_GRAPH` is `$FULL_GBZ`, `GBWT` is the pair's `<A>x<B>.gbwt`, and
`OUTPUT` is `<A>x<B>.gbz`. 20 lines.

```bash
cd "$WORKDIR"

sbatch --array=1-20%10 "$GBZ_BATCH" GBZ_construction_parameters.txt

mkdir -p GBWT_Files && mv ./*.gbwt GBWT_Files/
```

## 6. Deconstruct, compress and index

Each F1 GBZ is deconstructed to a VCF, then bgzipped and tabix-indexed, 20
tasks at each step.

```bash
cd "$WORKDIR"

mkdir -p GBZ_Files && mv ./*.gbz GBZ_Files/
mkdir -p GBZ_Deconstructed_VCFs
mv ./*.vcf.gz ./*.vcf.gz.tbi GBZ_Deconstructed_VCFs/
```

The resulting per-pair VCFs define the heterozygous sites at which reference
fraction is measured in `Analyze_Reference_Bias_Pileups.md`.
