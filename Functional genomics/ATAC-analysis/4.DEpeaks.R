run_peak_DE <- function(count_file,
                        out_csv = "DE_results.csv",
                        norm_counts_csv = "normalized_counts.csv",
                        heatmap_pdf = "diff_peak_heatmap.pdf",
                        condition_col = 2,
                        control_level = "CC032",
                        case_level    = "CC072",
                        lfc_threshold = 1,
                        padj_threshold = 0.05) {
  library(DESeq2)
  library(pheatmap)
  
  count.table <- read.delim(count_file, row.names = 1, check.names = FALSE)
  
  samples.vec <- colnames(count.table)
  comps <- strsplit(samples.vec, "_")
  coldata <- data.frame(
    sample = samples.vec,
    row.names = samples.vec,
    Group1 = factor(sapply(comps, `[`, 1)),
    Group2 = factor(sapply(comps, `[`, condition_col),
                    levels = c(control_level, case_level))
  )
  
  dds <- DESeqDataSetFromMatrix(
    countData = round(count.table),
    colData   = coldata,
    design    = ~ Group1 + Group2
  )
  
  dds <- estimateSizeFactors(dds)
  norm_counts <- counts(dds, normalized = TRUE)
  write.csv(as.data.frame(norm_counts),
            file = norm_counts_csv,
            row.names = TRUE)
  message("Normalized counts written to ", norm_counts_csv)
  
  # Compute logCPM from size-factor normalized counts
  col_sums <- colSums(norm_counts)
  cpm <- t(t(norm_counts) / col_sums) * 1e6
  logcpm <- log2(cpm + 1)
  
  # Differential analysis
  dds <- DESeq(dds)
  res <- results(dds, contrast = c("Group2", case_level, control_level))
  res <- na.omit(res)
  res$log10pvalue <- -log10(res$pvalue)
  res$Legends <- "NS"
  res$Legends[res$padj < padj_threshold & res$log2FoldChange >  lfc_threshold] <- "Up"
  res$Legends[res$padj < padj_threshold & res$log2FoldChange < -lfc_threshold] <- "Down"
  
  write.csv(as.data.frame(res),
            file = out_csv,
            row.names = TRUE)
  message("Finished differential analysis. Results written to ", out_csv)
  
  # Heatmap of diff peaks using logCPM
  diff_peaks <- rownames(res)[res$Legends %in% c("Up", "Down")]
  if (length(diff_peaks) > 1) {
    mat <- logcpm[diff_peaks, ]
    
    pdf(heatmap_pdf, width = 8, height = 10)
    pheatmap(mat,
             scale = "none",   # no internal scaling
             cluster_rows = TRUE,
             cluster_cols = TRUE,
             show_rownames = FALSE,
             main = paste("Differential Peaks (logCPM):", case_level, "vs", control_level))
    dev.off()
    message("Heatmap saved to ", heatmap_pdf)
  } else {
    message("No significant differential peaks to plot in heatmap.")
  }
  
  return(invisible(res))
}


res <- run_peak_DE(
  count_file       = "Fpan_mm10_peaks.count",
  out_csv          = "FCC072_vs_CC032_diff_peaks.csv",
  norm_counts_csv  = "FCC072_vs_CC032_normalized_counts.csv",
  heatmap_pdf      = "FCC072_vs_CC032_diff_peak_heatmap.pdf",
  condition_col    = 2,      
  control_level    = "CC032",
  case_level       = "CC072",
  lfc_threshold    = 1,
  padj_threshold   = 0.05
)