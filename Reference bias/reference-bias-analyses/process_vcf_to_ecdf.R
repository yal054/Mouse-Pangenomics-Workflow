#!/usr/bin/env Rscript
# Usage: Rscript process_ecdf.R <path_to_file>

# ---------------------------
# Parse Command Line Arguments
# ---------------------------
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Usage: Rscript process_ecdf.R <path_to_file>")
}
file_path <- args[1]

# ---------------------------
# Function: Import a Single Parsed VCF File
# ---------------------------
import_parsed_vcf <- function(file) {
  if (!file.exists(file)) {
    stop(paste("File", file, "does not exist."))
  }

  # Read the file assuming tab-delimited format with a header
  df <- read.table(file, header = TRUE, sep = "\t", stringsAsFactors = FALSE)

  # Parse the file name to extract metadata
  # Expected file name format: "CC-v1F.CC001xCC074.parsed.bed"
  fname <- basename(file)
  parts <- unlist(strsplit(fname, split = "\\."))
  if (length(parts) >= 3) {
    df$assembly <- parts[1]
    df$animal   <- parts[2]
  } else {
    warning(paste("File", fname, "does not conform to expected naming convention."))
  }

  return(df)
}

# ---------------------------
# Main Script Execution
# ---------------------------
cat("Processing file:", file_path, "\n")
# Import the data
pileupData <- import_parsed_vcf(file_path)

# Check for the required column
if (!"allele_fraction" %in% colnames(pileupData)) {
  stop("The input file does not contain the 'allele_fraction' column.")
}

# Calculate the empirical cumulative distribution function (ECDF)
ecdf_pileup <- ecdf(pileupData$allele_fraction)

# Create an output file name, prepending "ecdf_" to the input file name
output_file <- paste0("ecdf_", basename(file_path), ".rds")
saveRDS(ecdf_pileup, file = output_file)

cat("ECDF saved to", output_file, "\n")
