sed 's/mm10#0#//g' F1-v1_Founders-WSB_EiJxCAST_EiJ.vcf \
  | bcftools view --output-type v --samples ^GRCm39 - \
  | grep -Ev 'GT	\.	|GT	[012]	\.|GT	0	0|GT	1	1|GT	2	2' \
  | bcftools norm --output-type u --multiallelics - -f GRCm38.p6.renamed.filtered.fa - \
  | bcftools sort -m 90G -T $TMP-XXXXXX --write-index -o truth-set.F1-v1_Founders-WSB_EiJxCAST_EiJ.vcf.gz -
