# Build the CC Pangenome and deconstruct it to VCF

Merges the personalized traversals of the 40 CC RI lines with the founder
pangenome to produce the **CC Pangenome (CCP)**, then deconstructs it to a VCF
in GRCm38 coordinates and normalizes that VCF.

The resulting callset is used downstream by the RI population genetics, the
cCRE intersection and the exclusion annotations.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `SAMP_ROOT` | personalization results, one `CC<line>/sampled.gbz` per line |
| `FULL_GBZ` | founder pangenome graph, GBZ |
| `MM10_FA` | GRCm38 reference FASTA, for `bcftools norm` |
| `REFS_TO_DROP` | reference samples to remove from each GBWT |
| `GBWT_BATCH` | `run_make_and_rename_recombinant_only_gbwt.sh` |
| `CHUNK_BATCH` | `run_merge_gbwt_chunk.sh` |
| `VG`, `VCFBUB`, `VCFWAVE` | tool binaries |

```bash
WORKDIR=/path/to/RI_Personalization/Merge_personalized_walks_into_full_graph
SAMP_ROOT=/path/to/personalization_founder_CC/full
FULL_GBZ=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.gbz
MM10_FA=/path/to/mm10.fa
REFS_TO_DROP="C57BL_6_T2T_Yu,GRCm39,mm10"
GBWT_BATCH=run_make_and_rename_recombinant_only_gbwt.sh
CHUNK_BATCH=run_merge_gbwt_chunk.sh
VG=/path/to/vg
VCFBUB=/path/to/vcfbub
VCFWAVE=/path/to/vcfwave
```

Personalization was run upstream by a co-author.

## Outputs

| File | Use |
|---|---|
| `founder.plus_allCC.gbz` | the CC Pangenome graph |
| `founder.plus_allCC.deconstruct.mm10.vcf` | top-level deconstruction, no nesting |
| `founder.plus_allCC.deconstruct.mm10.raw.vcf.gz` | nested deconstruction (`-C -a`) |
| `founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.gz` | the normalized callset used downstream |

> Both deconstructions are kept. The top-level VCF represents complex regions as
> single mega-snarls. The `-a` version decomposes those into nested
> sub-variants, which `vcfbub` requires, but the decomposition also produces the
> spurious
> founder-only blocks documented in
> `../../Variant analysis/variant-analyses/ri-population-genetics/exclusions/Exclusion_Annotations.md`.

## 1. Set up and list the inputs

```bash
mkdir -p "$WORKDIR"/{00_lists,01_per_sample_gbwt,02_merge}
cd "$WORKDIR"

ls -1 "$SAMP_ROOT"/CC*/sampled.gbz > 00_lists/sampled_gbz.list
wc -l 00_lists/sampled_gbz.list        # expect 40
```

## 2. Extract the founder GBWT

Extracted once here and reused by the DO and saturation merges.

```bash
cd "$WORKDIR/02_merge"
"$VG" gbwt --num-threads 16 -o founder.gbwt -Z "$FULL_GBZ"
```

## 3. Extract a recombinant-only GBWT per line

Converts each GBZ to GFA, renames the `recombination` paths to the sample name,
builds a GBWT and drops the reference samples.

`run_make_and_rename_recombinant_only_gbwt.sh` reads one line per CC line from
`params.make_and_rename_recombinant_only_gbwt.tsv`, tab-separated:
`GBZ  SAMPLE  OUTD  REFS_TO_DROP`
`GBZ` is `$SAMP_ROOT/CC<line>/sampled.gbz`, `SAMPLE` is the name of its parent
directory (`CC<line>`), `OUTD` is `$WORKDIR/01_per_sample_gbwt` and
`REFS_TO_DROP` is the comma-separated `$REFS_TO_DROP`. 40 lines.

```bash
cd "$WORKDIR"

# Resources used: 96 GB, 8 CPUs per task; 10 concurrent
sbatch --array=1-40%10 "$GBWT_BATCH" \
  params.make_and_rename_recombinant_only_gbwt.tsv
```

## 4. Merge in chunks

`params.recombinant_only_gbwts.list` (in `$WORKDIR`): one per-sample GBWT path
(`01_per_sample_gbwt/CC*.gbwt`) per line (40 lines), split into chunks of 8 lines
(`02_merge/params.recombinant_only_gbwts.list.chunk_000` to `_004`).
`run_merge_gbwt_chunk.sh` reads `params.merge_chunks.tsv`, which lists the chunk
files, one per line (5 lines).

```bash
cd "$WORKDIR/02_merge"

# 40 samples / 8 per chunk = 5 chunks. Resources used: 64 GB, 8 CPUs per task.
sbatch --array=1-5%5 "$CHUNK_BATCH" params.merge_chunks.tsv
```

## 5. Merge the chunks, then add the founders

`params.merge_all_chunks.list`: one chunk GBWT (`chunk_*.gbwt`, written by
`run_merge_gbwt_chunk.sh`) per line (5 lines).

```bash
cd "$WORKDIR/02_merge"

"$VG" gbwt --num-threads 16 \
  -m $(tr '\n' ' ' < params.merge_all_chunks.list) \
  -o All_chunk_merged.gbwt

"$VG" gbwt --num-threads 20 \
  -m founder.gbwt All_chunk_merged.gbwt \
  -o founder.plus_allCC.gbwt
```

> `vg gbwt -m` inserts later indices into the first. Passing the smaller
> index first is faster; the founder GBWT is the smaller of the two here, so it
> leads. The DO merges follow the same ordering for the same reason.

## 6. Build the combined GBZ (this is the CC Pangenome)

```bash
cd "$WORKDIR/02_merge"

"$VG" gbwt --num-threads 20 \
  -x "$FULL_GBZ" founder.plus_allCC.gbwt \
  --gbz-format -g founder.plus_allCC.gbz
```

## 7. Deconstruct to VCF, both ways

```bash
cd "$WORKDIR/02_merge"

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)

# top-level only
"$VG" deconstruct --path-prefix mm10 -t 20 --verbose \
  founder.plus_allCC.gbz > founder.plus_allCC.deconstruct.mm10.vcf

# nested, for vcfbub
"$VG" deconstruct \
  founder.plus_allCC.gbz \
  -P mm10 \
  -C \
  -a \
  -t 20 \
| bgzip --threads 20 > founder.plus_allCC.deconstruct.mm10.raw.vcf.gz
```

## 8. Normalize: vcfbub, then bcftools norm and sort

`vcfbub -l 0 -r 100000` pops nested bubbles and drops sites whose reference
allele exceeds 100 kb, the same threshold used by the HPRC pangenome pipeline.

```bash
cd "$WORKDIR/02_merge"

eval $( spack load --sh rust@1.85.0 )

"$VCFBUB" -l 0 -r 100000 -i founder.plus_allCC.deconstruct.mm10.raw.vcf.gz \
  > founder.plus_allCC.deconstruct.mm10.vcfbub.vcf

eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)
bgzip founder.plus_allCC.deconstruct.mm10.vcfbub.vcf
tabix -p vcf founder.plus_allCC.deconstruct.mm10.vcfbub.vcf.gz

eval $( spack load --sh bcftools/yz7hzwn )   # bcftools 1.12 (build hash yz7hzwn)

bcftools norm -f "$MM10_FA" -Oz \
  -o founder.plus_allCC.deconstruct.mm10.vcfbub.norm.vcf.gz \
  founder.plus_allCC.deconstruct.mm10.vcfbub.vcf.gz

bcftools sort -Oz \
  -o founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.gz \
  founder.plus_allCC.deconstruct.mm10.vcfbub.norm.vcf.gz

tabix -p vcf founder.plus_allCC.deconstruct.mm10.vcfbub.norm.sorted.vcf.gz
```

## 9. vcfwave realignment, per chromosome

An additional decomposition of complex alleles. Run per chromosome; the whole
VCF at once is impractical.

> vcfwave needs a large toolchain loaded: gcc, cmake, bzip2, xz, zlib, pkgconf,
> py-pybind11, curl and libdeflate. The `spack load` lines name the builds used
> in the original analysis; load equivalent versions on your system.

```bash
cd "$WORKDIR/02_merge"

eval $( spack load --sh bcftools/yz7hzwn )   # bcftools 1.12 (build hash yz7hzwn)
eval $( spack load --sh samtools/5dgya4q )   # samtools 1.13 (build hash 5dgya4q)
for spec in gcc/g7v66i6 cmake/6mjoqms bzip2/rr5pqdl xz/mfhopfi zlib/2qdrps4 \
            pkgconf/r2fdlro py-pybind11/bqseav2 \
            curl@7.79.0%gcc@11.4.1 libdeflate@1.7%gcc@11.4.1; do
    eval $( spack load --sh "$spec" )
done

tabix -p vcf founder.plus_allCC.deconstruct.mm10.raw.vcf.gz

# per chromosome, e.g. chr19
bcftools view founder.plus_allCC.deconstruct.mm10.raw.vcf.gz -r chr19 \
  | bgzip > chr19.input.vcf.gz
tabix -p vcf chr19.input.vcf.gz

"$VCFBUB" --input chr19.input.vcf.gz -l 0 -r 100000 > chr19.vcfbub.vcf
"$VCFWAVE" -t 2 -I 1000 chr19.vcfbub.vcf > chr19.wave.vcf
```

To run across all chromosomes, submit `run_Batch_vcfwave.sh` as an array. It
reads one line per contig from `params.vcfwave.tsv`, tab-separated:
`INPUTVCF  CONTIG`
`INPUTVCF` is `founder.plus_allCC.deconstruct.mm10.raw.vcf.gz` on every line;
there is one line for each contig declared in the VCF header.
