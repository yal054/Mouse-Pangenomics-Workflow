# Gnomix + Gnofix phasing of CC RI lines using founder assemblies

## Overview
Phase the 40 CC RI line genotypes from the pangenome deconstruct VCF using
gnomix local ancestry inference + Gnofix phase correction. The 8 CC founder
strain assemblies serve as the reference "populations."

The founders are haploid/homozygous (inbred strains), making them unsuitable as
a shapeit4 reference panel (needs diploid haplotype diversity). The CC RI
genotypes are already locally phased in 10 Kb blocks from graph personalization
but lack long-range phase coherence. gnomix assigns each segment to a founder,
and Gnofix stitches the block-level phase into chromosome-scale haplotypes.

Produces the phased chr19 view of CC010 against its expected mosaic. The `.msp`
ancestry assignments also give a founder painting.

## Inputs

| Variable | Description |
|---|---|
| `WORKDIR` | working directory |
| `SOURCE_VCF` | deconstructed VCF, contig prefixes already stripped |
| `DIPLOID_SCRIPT` | `convert_haploid_to_diploid_vcf.py`, in this directory |
| `GMAP_SCRIPT` | `convert_qtl2_maps_to_gnomix.py`, in this directory |
| `TRAIN_BATCH` | `run_Batch_train_gnomix.sh` |
| `INFER_BATCH` | `run_Batch_gnomix.sh` |
| `GNOMIX_VENV` | gnomix virtualenv |
| `GNOMIX_CONFIG` | gnomix `config.yaml` |

```bash
WORKDIR=/path/to/Gnomix_CC_Phasing
SOURCE_VCF=/path/to/founder.plus_allCC.deconstruct.mm10.noprefix.vcf
DIPLOID_SCRIPT=convert_haploid_to_diploid_vcf.py
GMAP_SCRIPT=convert_qtl2_maps_to_gnomix.py
TRAIN_BATCH=run_Batch_train_gnomix.sh
INFER_BATCH=run_Batch_gnomix.sh
GNOMIX_VENV=/path/to/gnomix_env
GNOMIX_CONFIG=/path/to/gnomix/config.yaml
```

### Source VCF shape

- ~16 GB, uncompressed
- CHROM: chr1–chr19, chrX, chrY (`mm10#0#` prefix already stripped)
- Founders (10 columns, haploid GT): 129S1_SvImJ, A_J,
  C57BL_6J_T2T_Keane, C57BL_6_T2T_Yu, CAST_EiJ, CAST_EiJ_T2T_Keane,
  NOD_ShiLtJ, NZO_HlLtJ, PWK_PhJ, WSB_EiJ
- Reference column: GRCm39
- CC RI lines (40 columns, diploid GT), locally phased in 10 kb blocks

### Batch script parameter layouts

| Script | Columns | Resources |
|---|---|---|
| training | `SAMPLE_VCF OUTPUT_DIR CHROM PHASE GMAP REFERENCE SAMPLEMAP` | 32 GB, 1 CPU |
| inference | `SAMPLE_VCF OUTPUT_DIR CHROM PHASE MODEL` | 8 GB, 1 CPU |

Python for gnomix is 3.8.12 (`spack load --sh python/pudl6n3`), running in the
virtualenv above.

> The steps below use `bcftools@1.21`, `samtools@1.21` and `python@3.11.11`,
> newer than the versions used elsewhere in this repository. The Gnomix steps
> themselves use Python 3.8.12. On the original cluster these came from two
> separate spack installs, so steps needing both ran in separate shells.

**Outputs (per chromosome):**
- `query_file_phased.vcf`: Gnofix-corrected phased VCF
- `query_results.msp`: mosaic ancestry assignments (founder painting)
- `query_results.fb`: ancestry posterior probabilities
- `models/model_chm_<chr>/model_chm_<chr>.pkl`: trained model

---

## Setup working directory
```bash
mkdir -p "$WORKDIR"
cd "$WORKDIR"
mkdir -p RefPanel InputVCFs GeneticMaps Phased_VCFs Logs/Gnomix_CC Parameters
```

---

## Step 1: bgzip + tabix the source noprefix VCF
The source VCF is plain text. bgzip in-place so bcftools can region-query it.
```bash

# spack load lines name the builds used in the original analysis (tool@version/build-hash); load the same versions however you install software.
eval $( spack load --sh bcftools@1.21 )
eval $( spack load --sh samtools@1.21 )

bgzip -@ 8 "$SOURCE_VCF"
tabix -p vcf "${SOURCE_VCF}.gz"

```

### Confirm sample names and ploidy
```bash

eval $( spack load --sh bcftools@1.21 )


# List all sample names
bcftools query -l "${SOURCE_VCF}.gz"

# Spot-check: first 5 variants on chr1, confirming founders are haploid and CC RI diploid
bcftools view -r chr1 "${SOURCE_VCF}.gz" | head -n 55 | tail -n 5

```

---

## Step 2: Prepare reference panel (founders, SNPs only, diploid)
Extract 10 founder columns, filter to biallelic SNPs only (gnomix requirement),
convert haploid GT -> homozygous diploid, split by chromosome.
```bash

eval $( spack load --sh bcftools@1.21 )
eval $( spack load --sh samtools@1.21 )
eval $( spack load --sh python@3.11.11 )


FOUNDERS="129S1_SvImJ,A_J,C57BL_6J_T2T_Keane,C57BL_6_T2T_Yu,CAST_EiJ,CAST_EiJ_T2T_Keane,NOD_ShiLtJ,NZO_HlLtJ,PWK_PhJ,WSB_EiJ"

cd "$WORKDIR"/RefPanel

for chr in {1..19} X; do
  echo "Processing chr${chr}..."
  bcftools view \
    -s "$FOUNDERS" \
    -m2 -M2 \
    -v snps \
    -g ^miss \
    -r "chr${chr}" \
    "${SOURCE_VCF}.gz" \
  | python3 "$DIPLOID_SCRIPT" \
  | bgzip -@ 4 > "ref.chr${chr}.vcf.gz"
  tabix -p vcf "ref.chr${chr}.vcf.gz"
done

```

### Validate: confirm founders are now diploid
```bash
eval $( spack load --sh bcftools@1.21 )

cd "$WORKDIR"/RefPanel

# Should see 0|0 or 1|1, not bare 0 or 1
bcftools view -H ref.chr19.vcf.gz | head -3
```

### Count SNPs per chromosome in ref panel
```bash
cd "$WORKDIR"/RefPanel

eval $( spack load --sh bcftools@1.21 )

for f in ref.chr*.vcf.gz; do
  n=$( bcftools view -H "$f" | wc -l )
  echo "$f: $n"
done
```

---

## Step 3: Prepare CC RI input VCFs (SNPs only, per chromosome)
Extract 40 CC RI line columns, filter to biallelic SNPs, split by chromosome.
These are already diploid (locally phased in 10 Kb blocks from graph personalization).
```bash

eval $( spack load --sh bcftools@1.21 )
eval $( spack load --sh samtools@1.21 )


CC_SAMPLES="CC001,CC002,CC003,CC004,CC005,CC006,CC007,CC008,CC009,CC010,CC011,CC012,CC015,CC016,CC017,CC018,CC020,CC021,CC023,CC024,CC025,CC027,CC028,CC033,CC036,CC038,CC039,CC040,CC043,CC044,CC045,CC046,CC057,CC058,CC060,CC061,CC062,CC068,CC074,CC075"

cd "$WORKDIR"/InputVCFs

for chr in {1..19} X; do
  echo "Processing chr${chr}..."
  bcftools view \
    -s "$CC_SAMPLES" \
    -m2 -M2 \
    -v snps \
    -g ^miss \
    -r "chr${chr}" \
    "${SOURCE_VCF}.gz" \
    -Oz -o "CC_RI.chr${chr}.vcf.gz"
  tabix -p vcf "CC_RI.chr${chr}.vcf.gz"
done

```

### Count SNPs per chromosome in CC RI input
```bash
cd "$WORKDIR"/InputVCFs

eval $( spack load --sh bcftools@1.21 )

for f in CC_RI.chr*.vcf.gz; do
  n=$( bcftools view -H "$f" | wc -l )
  echo "$f: $n"
done
```

---

## Step 4: Download and convert mouse genetic maps

### Download R/qtl2 MMnGM maps (mm10/GRCm38)
Source: https://github.com/rqtl/qtl2data/tree/main/MMnGM
```bash
cd "$WORKDIR"/GeneticMaps

wget -O gmap_MMnGM.csv "https://raw.githubusercontent.com/rqtl/qtl2data/main/MMnGM/gmap_MMnGM.csv"
wget -O pmap_MMnGM.csv "https://raw.githubusercontent.com/rqtl/qtl2data/main/MMnGM/pmap_MMnGM.csv"
```

### Inspect downloaded format
```bash
cd "$WORKDIR"/GeneticMaps

head -3 gmap_MMnGM.csv
wc -l gmap_MMnGM.csv
head -3 pmap_MMnGM.csv
```

### Convert to gnomix .gmap format
gnomix format: `chrom  pos(bp)  pos_cm` (tab-delimited with header)
```bash
cd "$WORKDIR"/GeneticMaps

eval $( spack load --sh python@3.11.11 )

python3 "$GMAP_SCRIPT" \
  gmap_MMnGM.csv \
  pmap_MMnGM.csv \
  ./
```

### Validate output maps
```bash
cd "$WORKDIR"/GeneticMaps

ls -lh *.mouse.gmap | wc -l
head -5 chr1.mouse.gmap
head -5 chr19.mouse.gmap
```

---

## Step 5: Create sample map (.smap) for 8 founder populations
10 founder columns -> 8 populations (C57BL/6 and CAST each have two assembly versions).
```bash
cd "$WORKDIR"

cat > CC_founders.smap << 'EOF'
129S1_SvImJ	129S1
A_J	AJ
C57BL_6J_T2T_Keane	C57BL6
C57BL_6_T2T_Yu	C57BL6
CAST_EiJ	CAST
CAST_EiJ_T2T_Keane	CAST
NOD_ShiLtJ	NOD
NZO_HlLtJ	NZO
PWK_PhJ	PWK
WSB_EiJ	WSB
EOF

cat CC_founders.smap
wc -l CC_founders.smap
```

---

## Step 6: Build training params file
gnomix training mode takes 7 arguments per line:
`QUERY_VCF  OUTPUT_DIR  CHROM  PHASE  GMAP  REFERENCE_VCF  SAMPLEMAP`

Phase=True because input is already locally phased (10 Kb blocks); gnomix + Gnofix
will correct inter-block phase switches.

One line per chromosome, chr1-chr19 then chrX (chr19 is line 19), written to
`Parameters/Gnomix_CC_Mouse_Paremeters.tsv`.

---

## Step 7: Test on chr19 (smallest autosome)
chr19 is line 19 in the params file.
```bash
cd "$WORKDIR"

sbatch --array=19 --mem=32G \
  "$TRAIN_BATCH" \
  Parameters/Gnomix_CC_Mouse_Paremeters.tsv
```

### Inspect test output
```bash
cd "$WORKDIR"/gnomix_output_chr19

ls -lh

# Check phased VCF exists and has phased genotypes
head -55 query_file_phased.vcf | tail -5

# Check ancestry painting
head -5 query_results.msp

# Check model was trained
ls -lh models/
```

---

## Step 8: Submit full run (all 20 chromosomes)
Adjust memory based on chr19 test results. Start with 32G, throttle at 5 concurrent.
```bash
cd "$WORKDIR"

sbatch --array=1-20%5 --mem=32G \
  "$TRAIN_BATCH" \
  Parameters/Gnomix_CC_Mouse_Paremeters.tsv
```

---

## Step 9: Validate outputs across all chromosomes
```bash
cd "$WORKDIR"

# Check all phased VCFs exist
for chr in {1..19} X; do
  f="gnomix_output_chr${chr}/query_file_phased.vcf"
  if [ -f "$f" ]; then
    n=$( grep -cv '^#' "$f" )
    echo "chr${chr}: $n variants"
  else
    echo "chr${chr}: MISSING"
  fi
done
```

```bash
# Confirm genotypes are phased (| not /)
head -55 gnomix_output_chr1/query_file_phased.vcf | tail -3 | cut -f1-2,10-12
```

```bash
# Check ancestry assignments (msp)
for chr in {1..19} X; do
  f="gnomix_output_chr${chr}/query_results.msp"
  echo "chr${chr}: $( tail -n +2 "$f" | wc -l ) ancestry segments"
done
```

---

## Step 10: Collect and concatenate phased VCFs
bgzip individual chromosome phased VCFs, then concatenate.
```bash

eval $( spack load --sh bcftools@1.21 )
eval $( spack load --sh samtools@1.21 )

cd "$WORKDIR"

# bgzip + tabix each phased VCF
for chr in {1..19} X; do
  bgzip -@ 4 "gnomix_output_chr${chr}/query_file_phased.vcf"
  tabix -p vcf "gnomix_output_chr${chr}/query_file_phased.vcf.gz"
done

# Copy to Phased_VCFs/ with consistent naming
for chr in {1..19} X; do
  cp "gnomix_output_chr${chr}/query_file_phased.vcf.gz" "Phased_VCFs/CC_RI_phased.chr${chr}.vcf.gz"
  cp "gnomix_output_chr${chr}/query_file_phased.vcf.gz.tbi" "Phased_VCFs/CC_RI_phased.chr${chr}.vcf.gz.tbi"
done

# Concatenate
bcftools concat \
  Phased_VCFs/CC_RI_phased.chr{1..19}.vcf.gz \
  Phased_VCFs/CC_RI_phased.chrX.vcf.gz \
  -Oz -o CC_RI_phased.all_chr.vcf.gz

tabix -p vcf CC_RI_phased.all_chr.vcf.gz

```

### Final stats
```bash
eval $( spack load --sh bcftools@1.21 )

cd "$WORKDIR"

bcftools stats CC_RI_phased.all_chr.vcf.gz | grep "^SN"
bcftools query -l CC_RI_phased.all_chr.vcf.gz | wc -l
```

---

## Step 11: Cleanup
```bash
cd "$WORKDIR"

# Move slurm logs
mv slurm-*.out Logs/Gnomix_CC/
```

---

## Notes
- gnomix config at `"$GNOMIX_CONFIG"` uses default
  `window_size_cM: 0.2`, may need tuning for mouse SNP density
- The ancestry painting (.msp) shows which founder each CC RI segment descends
  from, for downstream QTL / haplotype visualization
- If memory is insufficient at 32G, increase to 64G (a larger panel of 1800
  samples needed 320G; this one has only 10 founders)
- The trained models (`.pkl`) can be reused for inference on new CC RI lines
  without retraining
