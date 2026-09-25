JFMVTheme<-theme_cowplot()+theme(
  text = element_text(family = "Arial"),
  plot.title = element_text(size = 13, face = "bold"),
  axis.title = element_text(size = 11.2, face = "bold"),
  axis.text = element_text(size = 9.6),
  axis.line = element_line(colour = "black"),
  legend.position = "right",
  legend.title = element_text(size = 9.6),
  legend.text = element_text(size = 9.6),
  legend.key = element_blank(),
  strip.text = element_text(size = 12, face = "bold"),
  strip.background = element_blank(),
  panel.background = element_rect(fill="white"),
  panel.grid.major=element_line(color="gray90", linetype="solid"),
  panel.grid.minor=element_line(color="gray95", linetype="solid", size=0.65),
  panel.border=element_rect(fill=NA, color="black", linewidth=2, linetype="solid")
)
