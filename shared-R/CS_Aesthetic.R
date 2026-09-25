

##### Add this line next line to code to load this is.
##### source("CS_Aesthetic.R")


library(ggplot2)
library(cowplot)
library(viridis)

theme_set(theme_cowplot())

CS.THEME<-theme(
  panel.background = element_rect(fill="white"),
  panel.grid.major=element_line(color="gray90", linetype="solid"), #adds major grid lines
  panel.grid.minor=element_line(color="gray95", linetype="solid", size=0.65), #adds minor grid lines
  panel.border=element_rect(fill=NA, color="black", size=1.5, linetype="solid"), #draws a black border around plot
  axis.line=element_blank(),
  text=element_text(colour = "black", family= "Arial")
)


CS.ColorPalette<-data.frame(
  Color=c(
    "#0d111b","#1c294a","#34487f",
    "#2d5879","#447ead","#9cb8c4",
    "#4d5a22","#7e9435","#b8dc37",
    "#333434","#555757","#aaaaaa",
    "#a5476b","#cb5683","#d398af",
    "#b2823f","#caa66e","#e9d8bd",
    "#c03a46","#f04857","#ff7f5d",
    "#781746","#bc316b","#ea3d85",
    "#0f1a57","#40106a","#6e1cb7",
    "#d4b337","#e1ca69","#eee2a7"
  ),
  Group=c(
    "Dark blues","Dark blues","Dark blues",
    "Light blues","Light blues","Light blues",
    "Greens","Greens","Greens",
    "Greys","Greys","Greys",
    "Pinks","Pinks","Pinks",
    "Tans","Tans","Tans",
    "Salmons","Salmons","Salmons",
    "Magentas","Magentas","Magentas",
    "Purples","Purples","Purples",
    "Yellows","Yellows","Yellows"
  ),
  Shade=c(
    "Dark","Medium","Light",
    "Dark","Medium","Light",
    "Dark","Medium","Light",
    "Dark","Medium","Light",
    "Dark","Medium","Light",
    "Dark","Medium","Light",
    "Dark","Medium","Light",
    "Dark","Medium","Light",
    "Dark","Medium","Light",
    "Dark","Medium","Light"
  )
)

#CS.ColorPalette$Color<-factor(CS.ColorPalette$Color,levels = as.character(CS.ColorPalette$Color))
CS.ColorPalette$Color<-as.character(CS.ColorPalette$Color)
CS.ColorPalette$Shade<-factor(CS.ColorPalette$Shade,levels = c("Dark","Medium","Light") )
CS.ColorPalette$Group<-factor(CS.ColorPalette$Group,levels = c("Yellows","Purples","Magentas","Salmons","Tans","Pinks","Greys","Greens","Light blues","Dark blues") )

# ColorPalettePlot<-ggplot(CS.ColorPalette,aes(x=Shade,y=Group,fill=Color))+
#   geom_tile()+
#   scale_fill_manual(values = as.character(CS.ColorPalette$Color))+
#   ggtitle("C.S. Color Palette")+CS.THEME
#
# ggsave2(filename = "ColorPalettePlot.png",plot = ColorPalettePlot)







