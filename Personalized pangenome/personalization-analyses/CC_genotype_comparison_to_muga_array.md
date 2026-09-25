# Why personalized traversals must be merged before deconstruction

Establishes, on a single line (CC001), that a personalized graph cannot be
deconstructed on its own and compared against the founder graph: the variant
sites do not correspond. `Merge_personalized_walks_into_full_graph.md` is
designed around this.

## The problem

Deconstructing CC001's personalized graph and deconstructing the founder graph
produce different variant positions and IDs, even though both start from the
same graph and use the same reference.

Two other explanations were ruled out:

| Candidate explanation | Ruled out by |
|---|---|
| Different reference | Re-deconstructed the founder graph against the same reference; positions still differ |
| Different starting graph | Both derive from the same founder graph |

The cause is that personalization changes which subgraphs are snarls.
Haplotype sampling removes paths, so a bubble present in the full graph may be
collapsed or re-bounded in the personalized graph, and `vg deconstruct` then
emits a different site.

Per-sample deconstruction therefore gives each sample its own,
incompatible site set. Genotypes cannot be compared across samples.

## The check that made the fix safe

If the reference walks themselves changed under sampling, merging the
personalized walks back into the full graph would be unsound. They do not:

```bash
VG=/path/to/vg
FULL_GBZ=/path/to/Yu-T2T_v2-refs_Keane-T2T_v3-founders.full.gbz
SAMPLED_GBZ=/path/to/personalization/full/CC001/sampled.gbz

"$VG" convert -t 16 -f "$FULL_GBZ"    > full.gfa
"$VG" convert -t 16 -f "$SAMPLED_GBZ" > CC001.sampled.gfa

grep "W" full.gfa        | grep "mm10" > full.mm10.wlines.tsv
grep "W" CC001.sampled.gfa | grep "mm10" > sampled.mm10.wlines.tsv

wc -l full.mm10.wlines.tsv sampled.mm10.wlines.tsv

LC_ALL=C sort -u full.mm10.wlines.tsv    > full.mm10.wlines.uniq.tsv
LC_ALL=C sort -u sampled.mm10.wlines.tsv > sampled.mm10.wlines.uniq.tsv

echo "sampled_not_in_full = $(LC_ALL=C comm -23 sampled.mm10.wlines.uniq.tsv full.mm10.wlines.uniq.tsv | wc -l)"
echo "full_not_in_sampled = $(LC_ALL=C comm -13 sampled.mm10.wlines.uniq.tsv full.mm10.wlines.uniq.tsv | wc -l)"
```

Same line count, and zero differences once sorted: the mm10 reference walks are
identical between the personalized and full graphs. The files are not
byte-identical, only reordered, so compare sorted sets rather than checksums.

The sample-specific walks are the `recombination` W-lines:

```bash
grep "W" CC001.sampled.gfa | cut -f2 | sort | uniq
```

## The fix, demonstrated on CC001

Merge the personalized GBWT into the founder GBWT, then deconstruct once.
All samples then share one site set.

```bash
"$VG" gbwt --num-threads 16 -o full.gbwt          -Z "$FULL_GBZ"
"$VG" gbwt --num-threads 16 -o cc001_sampled.gbwt -Z "$SAMPLED_GBZ"

"$VG" gbwt --num-threads 16 \
  -m full.gbwt cc001_sampled.gbwt \
  -o full.plus_cc001.gbwt
```

Build a GBZ from the merged GBWT and deconstruct it, then strip the `mm10#0#`
contig prefix as in `Merge_personalized_walks_into_full_graph.md` step 3.

## Splitting the result per chromosome

For the single-sample R analyses, the merged VCF is split by contig. Contigs are
taken from the VCF header rather than assumed.

```bash
# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh bcftools/6unbpgv )   # bcftools, version not recorded (build hash 6unbpgv)

VCF=full.plus_cc001_recomb.deconstruct.mm10.noprefix.vcf

bcftools view -h "$VCF" \
  | grep '^##contig=<ID=' \
  | sed -E 's/^##contig=<ID=([^,>]+).*/\1/' \
  > contigs.list

# bcftools -r needs an index, so work from a temporary compressed copy
bgzip -c "$VCF" > "${VCF}.tmp.gz"
tabix -p vcf "${VCF}.tmp.gz"

mkdir -p split_by_chrom
while read -r c; do
    bcftools view -r "$c" -Oz -o "split_by_chrom/${c}.vcf.gz" "${VCF}.tmp.gz"
    tabix -p vcf "split_by_chrom/${c}.vcf.gz"
done < contigs.list

rm -f "${VCF}.tmp.gz" "${VCF}.tmp.gz.tbi"
```

Despite the filename, no MUGA array comparison is run here. Validation across
all 40 lines is in `Compare_personalized_paths_to_mosaic_expectations.md`.
