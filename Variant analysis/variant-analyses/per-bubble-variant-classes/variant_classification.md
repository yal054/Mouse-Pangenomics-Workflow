# Per-bubble variant classification: specification

What `Assign_Variant_Classes_Per_Bubble.py` computes for each site of a
deconstructed pangenome VCF. Shared by the Founder Pangenome and Draft Mouse
Pangenome protocols in this directory.

## Per-site output fields

| # | Field |
|---|---|
| 1 | Chromosome |
| 2 | Position |
| 3 | ID |
| 4 | REF length |
| 5 | ALT lengths (comma separated) |
| 6 | Number of ALTs |
| 7 | Number of Ns in REF |
| 8 | Number of Ns in each ALT (comma separated) |
| 9 | Whether each ALT is missing, `.` (comma separated) |
| 10 | \|ALT length − REF length\| per ALT (comma separated) |
| 11 | Whether REF is longer than one base (boolean) |
| 12 | Assigned variant class per ALT (comma separated) |
| 13 | Unique variant-class label for the site (bitwise) |
| 14 | Genotype N-equivalency test per ALT (comma separated) |

## Variant class per ALT allele (field 12)

Decided from whether the ALT is missing, the absolute length difference against
REF, and the REF length:

| Condition | Class |
|---|---|
| ALT is missing | `missing` |
| length difference = 0, REF length > 0 | `SNV` |
| length difference > 0, REF length = 0 | `INDEL` |
| length difference > 0, REF length > 0 | `COMPOSITE` |
| length difference = 0, REF length = 0 | `MNV` |

## Site-level class label (field 13)

A bitmask over the classes present at the site:

| Class | Bit value |
|---|---|
| SNV | 1 |
| INDEL | 2 |
| COMPOSITE | 4 |
| MNV | 8 |
| GAP | 16 |

A site with both an SNV and an INDEL is labelled 3; SNV + INDEL + COMPOSITE is
7; a site with a single class carries that class's value alone.

## N-equivalency test (field 14)

Pangenome assemblies contain runs of `N`. For each ALT, this test treats every
block of `N` as a wildcard and asks whether any other allele at the site
matches it. Returned per ALT as `True` / `False`, or `NA` where the allele contains
no `N`.

Examples, REF first, then ALTs:

| Alleles | Reasoning | Result |
|---|---|---|
| `CTCC` / `CNCC,CCTC,CCT,CCCC` | `CNCC` → `C*CC`; both `CTCC` and `CCCC` match | `True,NA,NA,NA` |
| `CTCCGAC` / `CTNCGNC,CTCCGAC` | `CTNCGNC` → `CT*CG*`; `CTCCGAC` matches | `True,NA` |
| `CTCCGAC` / `CTNNNNNNC,CTCCGAG` | `CTNNNNNNC` → `CT*C`; `CTCCGAC` matches | `True,NA` |

An allele consisting entirely of `N` necessarily returns `True`.

An `N`-containing allele that wildcard-matches another allele is missing
sequence, not a real difference; counting it as a variant would inflate the
variant totals.

## Exploded output

`Split_Multi_ALT_Per_Bubble.py` expands the per-site table to one row per ALT
allele, so classes can be counted per allele rather than per site.

| Analysis level | Input |
|---|---|
| number of sites; sites per chromosome; ALTs per site; class composition per site | per-site table |
| total ALT alleles; alleles by class; alleles carrying `N` and their N-equivalency breakdown | exploded table |
