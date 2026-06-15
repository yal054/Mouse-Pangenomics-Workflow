**Methods**

**RagTag Work**

First, Samtools (v1.18 with htslib 1.18) was used to index the contig-level assembly FASTA files with the following command:

```
samtools faidx assembly.fna
```

Next, RagTag (v2.1.0) was utilized to scaffold the assemblies, using GCF_000001635.26_GRCm38.p6_genomic.fna as the reference assembly:

```
ragtag.py scaffold -r GRCm39 contig_level_assembly.fna -o directory_out
```

The ragtag.scaffold.fasta files were then processed to adjust the FASTA header names using the following command:

```
sed 's/\_RagTag//g' ragtag.scaffold.fasta > updated_ragtag.scaffold.fasta
```

Next, the RagTag FASTA output was split into primary and unplaced FASTA files using the following command:

```
awk '/^>/ { out = (/^>JARC/ ? "unplaced_contigs.fasta" : "primary_sequences.fasta") } { print >> out }' updated_ragtag.scaffold.fasta
```


Statistics were gathered from the ragtag.scaffold.stats file (note: these are on scaffolded assemblies which already contain gaps):

- placed_sequences
- placed_bp
- unplaced_sequences
- unplaced_bp
- gap_bp
- gap_sequences

Assembly files were renamed and normalized using Picardmetrics (version 0.2.4) with the following command:

```
java -jar /usr/bin/picard.jar NormalizeFasta I=ragtag_primary_assembly.fa O=normalized_ragtag_primary_assembly.fa
```

Results are archived here in Box:

- [Results](https://wustl.app.box.com/folder/313578899090)
- [Tables](https://wustl.app.box.com/file/1847840572120)

**Gap/Length Analysis Work**

Gap and sequence length analysis was performed on all RagTag-scaffolded and 75 CC assemblies using the Python script find_gaps.py.

Example command:

```
python find_gaps.py input.fasta output_gaps.bed output_stats.txt
```

Outputs from the script include:

- output_gaps.bed file with all gap locations in the assembly FASTA.
- output_stats.txt file with stats for each chromosome and the full assembly:
    1. Total length in base pairs (including gap sequence)
    2. Total number of gaps
    3. Total gap base pairs

All data is archived here in Box:

- [Data](https://wustl.app.box.com/folder/318882817290)
- [Stats Table](https://wustl.app.box.com/file/1847769930059)

**BUSCO Analysis Work**

To estimate assembly completeness, we performed BUSCO analysis (version 5.8.2) with the lineage tag mammalia_odb10 and mode genome:

```
busco -i input_assembly.fa -o output_busco -l mammalia_odb10 -m genome -c 16
```

Short summary flat files output by BUSCO were then evaluated and plotted using the included BUSCO script generate_plot.py:

```
python3 generate_plot.py –wd busco_short_summary_files/
```

All BUSCO data is archived here in Box:

- [BUSCO Data](https://wustl.app.box.com/folder/313579916441?s=tvmnpeu3qjoa045whtr9kvqkiczcpmcp)

**Liftoff Analysis Work**

Liftoff (v1.6.3) was performed on all assemblies to measure genome completeness and gene copy expansion. Gencode Mus_musculus.GRCm38.102.gtf was used as the liftover annotation file, and GRCm38.p6 (GCF_000001635.26) was used as the reference assembly.

The Gencode annotation file was processed to change chromosome names to match standard chromosome names:

```
sed -E 's/^(>NT_\[^ \]+).\*/\\1/; s/^(>NW_\[^ \]+).\*/\\1/; s/^(>NC_\[^ \]+) Mus musculus strain C57BL\\/6J chromosome (\[0-9\]+).\*/>chr\\2/; s/^(>NC_\[^ \]+) Mus musculus strain C57BL\\/6J chromosome X.\*/>chrX/; s/^(>NC_\[^ \]+) Mus musculus strain C57BL\\/6J chromosome Y.\*/>chrY/; s/^(>NC_005089.1) Mus musculus mitochondrion.\*/>chrM/' GCF_000001635.27_GRCm39_genomic.fna > GCF_000001635.27_GRCm39_genomic_renamed.fna
```


Liftoff was run with the -copies flag to annotate additional copies of genes. Example command:

```
liftoff -p 16 -g Mus_musculus.GRCm38.102.renamed.gtf -o output.gtf -u unmapped_features.txt -cds -copies genome.fasta renamed_GCF_000001635.26_GRCm38.p6_genomic.fna
```

Additional copies of the genes were identified and single-copy annotations were extracted using:

```
grep 'extra_copy_number "0"' "output_copies.gtf" > "single_copy.gtf"
```

Statistics gathered from single_copy.gtf:

- Total number of annotations
- Number of CDS annotations
- Number of exon annotations
- Number of five-prime UTR annotations
- Number of gene annotations
- Number of Selenocysteine annotations
- Number of start codon annotations
- Number of stop codon annotations
- Number of three-prime UTR annotations
- Number of transcript annotations

Additional statistics were generated from output_copies.gtf:

- Total number of extra annotations:

```
awk '$0 ~ /extra_copy_number "(\[1-9\]\[0-9\]\*|\[0-9\]+\\.\[0-9\]+)"/' "output_copies.gtf" > "extra_annotations.txt" && wc -l “extra_annotations.txt"
```

- Gene extra copies:

```
awk -F'\\t' '$3 == "gene" { for (i = 1; i <= NF; i++) if ($i ~ /copy_num_ID/) { split($i, a, "\\""); id = a\[2\]; print id } }' "extra_annotations.txt" | wc -l
```


- Unique list of ‘copied’ genes:

```
awk -F'\\t' '$3 == "gene" {

for (i = 1; i <= NF; i++)

if ($i ~ /copy_num_ID/) {

split($i, a, "\\"");

id = a\[2\];

print id

}

}' "extra_annotations.txt" | sort -u | \\

awk -F'\_' '{

if ($1 != prev) {

if (prev)

print prev, max;

prev = $1;

max = $2

} else if ($2 > max) {

max = $2

}

} END {

if (prev)

print prev, max

}' | \\

awk '{gsub(" ", "\\t"); print}' > "unique_list_of_genes_copied.txt” && wc -l “unique_list_of_genes_copied.txt"
```


- Number of unmapped features:


```
wc -l unmapped_features.txt
```

All Liftoff data is archived here in Box:

- [Liftoff Data](https://wustl.app.box.com/folder/313580591216)
- [Main Data Table](https://wustl.app.box.com/file/1844081646363)

**Assembly N50 (Contig and Scaffold)**

Assembly N50 values were taken from NCBI’s genome navigator:

- [NCBI Genome Navigator](https://www.ncbi.nlm.nih.gov/datasets/genome/?taxon=10090)

All assembly N50 numbers (contig and scaffold) as well as plots are archived here:

- [N50 Data and Plots](https://wustl.app.box.com/folder/319167297524)