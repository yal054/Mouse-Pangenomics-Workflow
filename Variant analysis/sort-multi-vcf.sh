JOBNAME="sort-multi-vcf"

"bcftools sort -m 350G -T bcftools-XXXXXX \
   --write-index -o sorted.multi.sorted-normed-vcfwaved-Founders.vcf.gz multi.sorted-normed-vcfwaved-Founders.vcf"
