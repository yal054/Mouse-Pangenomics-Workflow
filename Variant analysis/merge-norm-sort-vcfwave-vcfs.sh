"bcftools concat \
   --output-type u \
   split_vcfs/sorted*vcf.gz \
  | bcftools norm \
   --output-type u \
   -m -any \
   - \
  | bcftools sort -m 350G -T bcftools-XXXXXX \
   --write-index -o sorted-normed-vcfwaved-Founders.vcf.gz -"
