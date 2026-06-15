awk 'BEGIN{OFS="\t"}
/^#/ {next}
{
  if ($0 !~ /transcript_id "/) next           # drop anything without transcript_id
  seq=$1
  sub(/^chr/,"",seq)                          # strip any leading "chr" if present
  if (seq=="MT") seq="M"                      # Ensembl MT -> graph uses M
  if (seq ~ /^(1[0-9]|[1-9]|X|Y|M)$/) {       # keep only canonical chromosomes
    $1 = "C57BL_6_T2T_Yu#0#chr" seq
    print
  }
}' mhaESC_v1.1_with_mT2T-Y_v1.0.250617_updated_headers_liftoff_liftover_gencode.Mus_musculus.GRCm38.102_copies.gtf > Mus_musculus.mhaESC_v1.1_with_mT2T-Y_v1.0.250617.graphpaths.tx.gtf

# Normalize attributes in-place from the tx GTF:
awk 'BEGIN{OFS="\t"}
!/^#/ && NF>=9 {
  # Normalize whitespace INSIDE the 9th field (attributes)
  gsub(/\t/," ",$9);                     # tabs -> spaces
  gsub(/  +/," ",$9);                    # collapse multiple spaces
  gsub(/[[:space:]]*;[[:space:]]*/,"; ",$9);  # standardize semicolon spacing
  gsub(/[[:space:]]+"/," \"",$9);        # ensure one space before the opening quote
  sub(/[[:space:]]+$/,"",$9);            # trim trailing spaces
  print; next
}
{ print }' Mus_musculus.mhaESC_v1.1_with_mT2T-Y_v1.0.250617.graphpaths.tx.gtf > Mus_musculus.mhaESC_v1.1_with_mT2T-Y_v1.0.250617.graphpaths.tx.norm.gtf

# Rebuild a valid 9th field by joining $9..$NF, fix spacing, and force NF=9
awk -F'\t' 'BEGIN{OFS="\t"}
!/^#/ && NF>=9 {
  attr = $9;
  for (i=10; i<=NF; i++) attr = attr " " $i;   # join extras with spaces
  gsub(/\t/," ",attr);                         # remove any stray tabs
  gsub(/  +/," ",attr);                        # collapse multiple spaces
  gsub(/[[:space:]]*;[[:space:]]*/,"; ",attr); # normalize semicolon spacing
  gsub(/[[:space:]]+"/," \"",attr);            # ensure one space before quotes
  sub(/[[:space:]]+$/,"",attr);                # trim trailing space
  $9 = attr; NF = 9; print; next
}
{ print }' Mus_musculus.mhaESC_v1.1_with_mT2T-Y_v1.0.250617.graphpaths.tx.norm.gtf > Mus_musculus.mhaESC_v1.1_with_mT2T-Y_v1.0.250617.graphpaths.tx.fixed.gtf
