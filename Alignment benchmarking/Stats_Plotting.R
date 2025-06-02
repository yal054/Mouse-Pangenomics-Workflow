# Load required libraries
library(ggplot2)
library(reshape2)
library(dplyr)
library(ggpubr)
library(tidyr)
library(svglite)

# 1. Read in all TSV files
# Original simulated stats tables
CC_stats_table   <- read.table("/Users/zheng/Desktop/Manuscript_PM/data/haploid.CC.vg_stats.tsv", 
                               header = TRUE, sep = "\t", stringsAsFactors = FALSE)
F1_stats_table   <- read.table("/Users/zheng/Desktop/Manuscript_PM/data/haploid.F1.vg_stats.tsv", 
                               header = TRUE, sep = "\t", stringsAsFactors = FALSE)
LT_stats_table   <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/haploid.LT.vg_stats.tsv", 
                               header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Simulated surjected graph stats
Surj_CC_table <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/New_Shell_Stats/gam_surjected_bam/CC-v1F/surjected.haploid.CC.custom_stats.tsv", 
                            header = TRUE, sep = "\t", stringsAsFactors = FALSE)
Surj_F1_table <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/New_Shell_Stats/gam_surjected_bam/F1-v2ref/surjected.haploid.F1.custom_stats.tsv",
                            header = TRUE, sep = "\t", stringsAsFactors = FALSE)
Surj_LT_table <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/New_Shell_Stats/gam_surjected_bam/LT/surjected.haploid.LT.custom_stats.tsv",
                            header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Linear simulated stats (refv2 and self)
refv2_table   <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/New_Shell_Stats/refv2/haploid.refv2.custom_stats.tsv", 
                            header = TRUE, sep = "\t", stringsAsFactors = FALSE)
self_table    <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/New_Shell_Stats/self/haploid.Self.custom_stats.tsv", 
                            header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Real (unsurjected) stats tables
real_CC_table  <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/real.haploid.CC.vg_stats.tsv", 
                             header = TRUE, sep = "\t", stringsAsFactors = FALSE)
real_F1_table  <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/real.haploid.F1.vg_stats.tsv", 
                             header = TRUE, sep = "\t", stringsAsFactors = FALSE)
real_refv2_table <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/New_Shell_Stats/real_refv2/real.haploid.refv2.custom_stats.tsv", 
                               header = TRUE, sep = "\t", stringsAsFactors = FALSE)
real_self_table <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/New_Shell_Stats/real_self/real.haploid.Self.custom_stats.tsv",
                              header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Real surjected stats tables
real_Surj_CC <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/New_Shell_Stats/gam_surjected_bam/real-CC-v1F/real.surjected.haploid.CC.custom_stats.tsv", 
                           header = TRUE, sep = "\t", stringsAsFactors = FALSE)
real_Surj_F1 <- read.table("/Users/zheng/Desktop/Manuscript_PM/Data/New_Shell_Stats/gam_surjected_bam/real-F1-v2ref/real.surjected.haploid.F1.custom_stats.tsv",
                           header = TRUE, sep = "\t", stringsAsFactors = FALSE)

clean_metric_name <- function(metric) {
  # strip trailing “_rate”, then turn ALL underscores into spaces
  no_suffix <- sub("_rate$", "", metric)
  gsub("_", " ", no_suffix)
}

# 2. Label the 'reference' column
CC_stats_table$reference        <- "CC (Simulated-Unsurjected)"
F1_stats_table$reference        <- "F1 (Simulated-Unsurjected)"
LT_stats_table$reference        <- "LT (Simulated-Unsurjected)"
Surj_CC_table$reference         <- "CC (Simulated-Surjected)"
Surj_F1_table$reference         <- "F1 (Simulated-Surjected)"
Surj_LT_table$reference         <- "LT (Simulated-Surjected)"
refv2_table$reference           <- "GRCm38 (Simulated)"
self_table$reference            <- "Self (Simulated)"
real_CC_table$reference         <- "CC (Real-Unsurjected)"
real_F1_table$reference         <- "F1 (Real-Unsurjected)"
real_refv2_table$reference      <- "GRCm38 (Real)"
real_self_table$reference       <- "Self (Real)"
real_Surj_CC$reference          <- "CC (Real-Surjected)"
real_Surj_F1$reference          <- "F1 (Real-Surjected)"

# 3. Combine all tables
stats_data <- bind_rows(
  CC_stats_table, F1_stats_table, LT_stats_table,
  Surj_CC_table, Surj_F1_table, Surj_LT_table,
  refv2_table, self_table,
  real_CC_table, real_F1_table, real_refv2_table, real_self_table,
  real_Surj_CC, real_Surj_F1
)

# 4. Convert key columns to numeric
numeric_cols <- c("Total_alignments","Total_aligned","Total_perfect",
                  "Total_gapless","Total_properly_paired","MapQ_60_reads")
stats_data[numeric_cols] <- lapply(stats_data[numeric_cols], as.numeric)

# 5. Compute mapping metrics
stats_data <- stats_data %>%
  mutate(
    Mapping_rate         = Total_aligned / Total_alignments,
    Perfect_rate         = Total_perfect / Total_aligned,
    Gapless_rate         = Total_gapless / Total_aligned,
    Properly_paired_rate = Total_properly_paired / Total_alignments,
    MapQ60_rate          = MapQ_60_reads / Total_aligned
  )

# 6. Add a 'type' column (Simulated vs Real)
stats_data$type <- ifelse(grepl("Simulated", stats_data$reference), "Simulated", "Real")

# 7. Melt into long format for plotting
metrics_long <- melt(
  stats_data,
  id.vars      = c("sample","reference","type"),
  measure.vars = c("Mapping_rate","Perfect_rate","Gapless_rate",
                   "Properly_paired_rate","MapQ60_rate"),
  variable.name = "Metric", value.name = "Rate"
)

# 8. Prepare output directories
base_dir <- "plots"
sim_dir  <- "/Users/zheng/Desktop/Manuscript_PM/Data/plots/Simulated"
real_dir <- "/Users/zheng/Desktop/Manuscript_PM/Data/plots/Real"
stats_dir <- "/Users/zheng/Desktop/Manuscript_PM/Data/stats_export"
dir.create(sim_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(real_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(stats_dir, recursive = TRUE, showWarnings = FALSE)

# 9. Define color palette
custom_colors <- c(
  "CC (Simulated-Unsurjected)"     = "#ff7f0e",
  "CC (Simulated-Surjected)"       = "#d62728",
  "F1 (Simulated-Unsurjected)"     = "#2ca02c",
  "F1 (Simulated-Surjected)"       = "#9467bd",
  "LT (Simulated-Unsurjected)"     = "#1f77b4",
  "LT (Simulated-Surjected)"       = "#8c564b",
  "GRCm38 (Simulated)"           = "#c5b0d5",
  "Self (Simulated)"               = "#ffbb78",
  "CC (Real-Unsurjected)"          = "#7f7f7f",
  "CC (Real-Surjected)"            = "#17becf",
  "F1 (Real-Unsurjected)"          = "#bcbd22",
  "F1 (Real-Surjected)"            = "#9edae5",
  "GRCm38 (Real)"                = "#c49c94",
  "Self (Real)"                    = "#ff9896"
)

# Helper that converts the full "reference" string into a cleaner legend label
clean_label <- function(ref) {
  # Split into base & suffix (text inside parentheses)
  base   <- trimws(sub("\\s*\\(.*",  "", ref))        # e.g. "CC"
  suffix <- trimws(sub(".*\\(",    "", sub("\\)", "", ref)))  # e.g. "Simulated‑Surjected"
  
  # Expand base names
  base_long <- dplyr::recode(
    base,
    "CC"   = "CC",
    "F1"   = "F1",
    "LT"   = "LT",
    "Self" = "Self Genome",
    .default = base        # keep others (e.g. GRCm38) unchanged
  )
  # Keep suffix as lower‑case for readability
  suffix <- tolower(suffix)
  paste0(base_long, " (", suffix, ")")
}

legend_title <- "Reference (data format)"   # shown once per plot

# Export raw statistics counts for all groups
# Create a function to export raw stats for each reference group
export_raw_stats <- function(data, output_dir) {
  # Get unique reference groups
  references <- unique(data$reference)
  
  # For each reference group, export raw statistics
  for (ref in references) {
    # Filter data for this reference
    ref_data <- data %>% 
      filter(reference == ref) %>%
      select(sample, Total_alignments, Total_aligned, Total_perfect, 
             Total_gapless, Total_properly_paired, MapQ_60_reads)
    
    # Create clean filename
    clean_ref <- gsub(" ", "_", ref)
    clean_ref <- gsub("[\\(\\)]", "", clean_ref)
    
    # Export as TSV
    output_file <- file.path(output_dir, paste0("raw_stats_", clean_ref, ".tsv"))
    write.table(ref_data, file = output_file, 
                sep = "\t", row.names = FALSE, quote = FALSE)
    
    cat(sprintf("Exported raw statistics for %s to %s\n", ref, output_file))
  }
}

# Export statistics separately for real and simulated data
cat("\n--- Exporting Raw Statistics ---\n")

# Export real data statistics
real_data <- stats_data %>% filter(type == "Real")
cat("Exporting real data statistics...\n")
export_raw_stats(real_data, stats_dir)

# Export simulated data statistics
sim_data <- stats_data %>% filter(type == "Simulated")
cat("Exporting simulated data statistics...\n")
export_raw_stats(sim_data, stats_dir)

# Export summarized tables as requested
cat("\n--- Exporting Summarized Tables ---\n")

# Function to create summarized tables for each reference group
export_summarized_tables <- function(data, output_dir) {
  # Group data
  data_summary <- data %>%
    group_by(reference) %>%
    summarize(
      Samples = n(),
      Avg_Total_alignments = mean(Total_alignments),
      Avg_Total_aligned = mean(Total_aligned),
      Avg_Total_perfect = mean(Total_perfect),
      Avg_Total_gapless = mean(Total_gapless),
      Avg_Total_properly_paired = mean(Total_properly_paired),
      Avg_MapQ_60_reads = mean(MapQ_60_reads),
      Avg_Mapping_rate = mean(Mapping_rate),
      Avg_Perfect_rate = mean(Perfect_rate),
      Avg_Gapless_rate = mean(Gapless_rate),
      Avg_Properly_paired_rate = mean(Properly_paired_rate),
      Avg_MapQ60_rate = mean(MapQ60_rate)
    )
  
  # Export as TSV
  output_file <- file.path(output_dir, 
                           ifelse(unique(data$type) == "Real", 
                                  "real_libraries_summary.tsv", 
                                  "simulated_libraries_summary.tsv"))
  
  write.table(data_summary, file = output_file, 
              sep = "\t", row.names = FALSE, quote = FALSE)
  
  cat(sprintf("Exported summarized table for %s libraries to %s\n", 
              unique(data$type), output_file))
}

# Export summarized tables
export_summarized_tables(real_data, stats_dir)
export_summarized_tables(sim_data, stats_dir)

# Create a combined report with pretty formatting
cat("\n--- Creating Combined Report ---\n")

# Function to create a nicely formatted report
create_combined_report <- function(data, output_dir, type_label) {
  # Create reference categories
  references <- unique(data$reference)
  
  # Create a dataframe to store results
  report_df <- data.frame(
    Sample = character(),
    Reference = character(),
    Total_alignments = numeric(),
    Mapping_rate = numeric(),
    Perfect_rate = numeric(),
    Gapless_rate = numeric(),
    MapQ60_rate = numeric(),
    stringsAsFactors = FALSE
  )
  
  # Fill in the report dataframe
  for (ref in references) {
    ref_data <- data %>% 
      filter(reference == ref) %>%
      select(sample, reference, Total_alignments, Mapping_rate, 
             Perfect_rate, Gapless_rate, MapQ60_rate)
    
    report_df <- rbind(report_df, ref_data)
  }
  
  # Format rates as percentages
  report_df$Mapping_rate <- sprintf("%.2f%%", report_df$Mapping_rate * 100)
  report_df$Perfect_rate <- sprintf("%.2f%%", report_df$Perfect_rate * 100)
  report_df$Gapless_rate <- sprintf("%.2f%%", report_df$Gapless_rate * 100)
  report_df$MapQ60_rate <- sprintf("%.2f%%", report_df$MapQ60_rate * 100)
  
  # Format total alignments with commas
  report_df$Total_alignments <- format(report_df$Total_alignments, big.mark = ",")
  
  # Export as CSV for easy Excel viewing
  output_file <- file.path(output_dir, paste0(type_label, "_libraries_report.csv"))
  write.csv(report_df, file = output_file, row.names = FALSE)
  
  cat(sprintf("Exported combined report for %s libraries to %s\n", 
              type_label, output_file))
}

# Create combined reports
create_combined_report(real_data, stats_dir, "real")
create_combined_report(sim_data, stats_dir, "simulated")


# 10. MAIN PLOTTING LOOP (all six groups, Simulated & Real)
for (m in unique(metrics_long$Metric)) {
  for (t in c("Simulated","Real")) {
    
    # filter exactly as you had it
    if (m == "Perfect_rate") {
      subset_df <- metrics_long %>%
        filter(Metric == m, type == t,
               !grepl("Surjected", reference),
               !grepl("LT",        reference))
    } else {
      subset_df <- metrics_long %>%
        filter(Metric == m, type == t,
               !grepl("LT", reference))
    }
    if (nrow(subset_df)==0) next
    
    # reorder factor levels
    if (t=="Simulated") {
      levels_order <- c(
        "GRCm38 (Simulated)",
        "Self (Simulated)",
        "CC (Simulated-Unsurjected)",
        "F1 (Simulated-Unsurjected)",
        "CC (Simulated-Surjected)",
        "F1 (Simulated-Surjected)"
      )
    } else {
      levels_order <- c(
        "GRCm38 (Real)",
        "Self (Real)",
        "CC (Real-Unsurjected)",
        "F1 (Real-Unsurjected)",
        "CC (Real-Surjected)",
        "F1 (Real-Surjected)"
      )
    }
    subset_df$reference <- factor(subset_df$reference, levels=levels_order)
    
    # build plot
    clean_m    <- clean_metric_name(m)
    title_text <- paste0(clean_m, " (", t, ")")
    
    
    p <- ggplot(subset_df, aes(reference, Rate, fill=reference)) +
      geom_boxplot(color="black", outlier.shape=NA, alpha=0.85, width=0.6) +
      geom_jitter(color="grey40", width=0.15, size=0.8, alpha=0.3) +
      
      # full palette, no legend
      scale_fill_manual(values=custom_colors, guide="none") +
      
      # clean x-axis labels with _only_ the human-friendly text:
      scale_x_discrete(labels = c(
        "GRCm38 (Simulated)"         = "GRCm38 (linear)",
        "Self (Simulated)"           = "Self Genome (linear)",
        "CC (Simulated-Unsurjected)" = "CC (native)",
        "F1 (Simulated-Unsurjected)" = "F1 (native)",
        "CC (Simulated-Surjected)"   = "CC (surjected)",
        "F1 (Simulated-Surjected)"   = "F1 (surjected)",
        "GRCm38 (Real)"              = "GRCm38 (linear)",
        "Self (Real)"                = "Self Genome (linear)",
        "CC (Real-Unsurjected)"      = "CC (native)",
        "F1 (Real-Unsurjected)"      = "F1 (native)",
        "CC (Real-Surjected)"        = "CC (surjected)",
        "F1 (Real-Surjected)"        = "F1 (surjected)"
      )) +
      
      labs(title = title_text, x = NULL, y = "Rate") +
      expand_limits(y = 1) +
      theme_minimal(base_size=18) +
      theme(
        plot.title  = element_text(hjust=0, face="bold", size=15),
        axis.text.x = element_text(angle=35, hjust=1, size=15),
        axis.title.y= element_text(size=17),
        plot.margin = margin(20,30,50,40)
      )
    
    if (m == "MapQ60_rate" && t == "Simulated") {
      p <- p + scale_y_continuous(limits = c(0.92, 1.00))
    } else if (m == "MapQ60_rate" && t == "Real") {
      p <- p + scale_y_continuous(limits = c(0.50, 1.00))
    } else if (m == "Perfect_rate" && t == "Real") {
      p <- p + scale_y_continuous(limits = c(0.30, 1.00))
    }
    
    # save with your existing logic…
    out_dir <- if(t=="Simulated") sim_dir else real_dir
    num_lv <- length(levels(subset_df$reference))
    w <- if(t=="Simulated") 5 else max(4.5, min(5.5, 0.7*num_lv))
    h <- if(m=="MapQ60_rate") 6.6 else 6
    ggsave(file.path(out_dir, paste0(m,"_", tolower(t),".svg")),
           p, width=w, height=h)
  }
}










# ======= ADDITIONAL CODE FOR FOCUSED GROUPS (LT, CC, and GRCm38) =======

library(ggplot2)
library(reshape2)
library(dplyr)

# 1. Filter the data for only LT, CC, and GRCm38 groups, excluding any “Surjected”
filtered_data <- stats_data %>%
  filter(grepl("LT|CC|GRCm38", reference) &
         !grepl("Surjected", reference))

# 2. Convert the filtered data to long format for plotting
filtered_metrics_long <- melt(
  filtered_data,
  id.vars      = c("sample", "reference", "type"),
  measure.vars = c("Mapping_rate", "Perfect_rate", "Gapless_rate",
                   "Properly_paired_rate", "MapQ60_rate"),
  variable.name = "Metric", value.name = "Rate"
)

# 3. Create a new color palette for just these groups
filtered_colors <- c(
  "CC (Simulated-Unsurjected)" = "#ff7f0e",
  "CC (Simulated-Surjected)"   = "#d62728",
  "CC (Real-Unsurjected)"      = "#7f7f7f",
  "CC (Real-Surjected)"        = "#17becf",
  "LT (Simulated-Unsurjected)" = "#1f77b4",
  "LT (Simulated-Surjected)"   = "#8c564b",
  "GRCm38 (Simulated)"         = "#c5b0d5",
  "GRCm38 (Real)"              = "#c49c94"
)

# 4. Create a new output directory for these specific plots
focused_dir <- "/Users/zheng/Desktop/Manuscript_PM/Data/plots/Focused_Groups"
dir.create(focused_dir, recursive = TRUE, showWarnings = FALSE)

# 2. In the loop, do exactly the same pattern:
for (m in unique(filtered_metrics_long$Metric)) {
  for (t in c("Simulated","Real")) {
    
    subset_df <- filtered_metrics_long %>%
      filter(Metric==m, type==t)
    if (nrow(subset_df)==0) next
    
    # reorder only the levels you actually have
    if (t=="Simulated") {
      levels_order <- c(
        "GRCm38 (Simulated)",
        "CC (Simulated-Unsurjected)",
        "LT (Simulated-Unsurjected)",
        "CC (Simulated-Surjected)",
        "LT (Simulated-Surjected)"
      )
    } else {
      levels_order <- c(
        "GRCm38 (Real)",
        "CC (Real-Unsurjected)",
        "CC (Real-Surjected)"
        # (Real-LT) omitted if you don’t have any real-LT data
      )
    }
    subset_df$reference <- factor(subset_df$reference, levels=levels_order)
    
    # build plot
    
    # new
    clean_m    <- clean_metric_name(m)
    title_text <- paste0(clean_m, " (", t, ")")
    
    
    p2 <- ggplot(subset_df, aes(reference, Rate, fill=reference)) +
      geom_boxplot(color="black", outlier.shape=NA, width=0.6, alpha=0.85) +
      geom_jitter(color="grey40", width=0.15, size=0.8, alpha=0.3) +
      scale_fill_manual(values=filtered_colors, guide="none") +
      scale_x_discrete(labels = c(
        "GRCm38 (Simulated)"         = "GRCm38 (linear)",
        "CC (Simulated-Unsurjected)" = "CC (native)",
        "CC (Simulated-Surjected)"   = "CC (surjected)",
        "LT (Simulated-Unsurjected)" = "LT (native)",
        "LT (Simulated-Surjected)"   = "LT (surjected)",
        "GRCm38 (Real)"              = "GRCm38 (linear)",
        "CC (Real-Unsurjected)"      = "CC (native)",
        "CC (Real-Surjected)"        = "CC (surjected)"
      )) +
      labs(title=title_text, x=NULL, y="Rate") +
      expand_limits(y=1) +
      theme_minimal(base_size=18) +
      theme(
        plot.title  = element_text(hjust=0,face="bold",size=15),
        axis.text.x = element_text(angle=35,hjust=1,size=15),
        axis.title.y= element_text(size=17),
        plot.margin = margin(20,30,50,40)
      )
    
    if (m == "MapQ60_rate" && t == "Simulated") {
      p2 <- p2 + scale_y_continuous(limits = c(0.92, 1.00))
    } else if (m == "MapQ60_rate" && t == "Real") {
      p2 <- p2 + scale_y_continuous(limits = c(0.60, 1.00))
    }
    
    # save
    nlv <- length(levels(subset_df$reference))
    w2  <- max(4.5, min(6.0, 0.9*nlv))
    ggsave(
      file.path(focused_dir,paste0(clean_m,"_",tolower(t),"_focused.svg")),
      p2, width=w2, height=6
    )
  }
}