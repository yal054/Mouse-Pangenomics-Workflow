JOBNAME="filter-non-biallelics"

"bcftools view --min-alleles 2 --max-alleles 2 --write-index -o biallelic-only.sorted.multi.sorted-normed-vcfwaved-Founders.vcf.gz sorted.multi.sorted-normed-vcfwaved-Founders.vcf.gz"
