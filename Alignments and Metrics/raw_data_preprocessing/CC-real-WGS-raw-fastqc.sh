mkdir -p fastqc_logs raw-fastqc

for fq in *.fastq.gz; do
  FILENAME="${fq%.fastq.gz}"

   "fastqc \
      --memory 10000 \
      -o raw-fastqc \
      ${fq}"
done
