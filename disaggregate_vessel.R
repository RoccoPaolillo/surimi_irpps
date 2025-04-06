library(dplyr)
library(ggplot2)
library(readxl)

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/surimi_irpps/GSA9")

# upload dataset
effortcd <- read.csv("effort_CS.csv",sep =",")[,-1]
gfw <- read.csv("GFW_Vessel_info.csv",sep =",")[,-1]
names(gfw)[names(gfw) == "Vessel.Name"] <- "vessel_name"
gfw[gfw$MMSI == 247222320,]$vessel_name <- "MP LEDO"
gfw[gfw$MMSI == 247045120,]$vessel_name <- "ARINA MADRE"
gfw_clear <-  gfw[!is.na(gfw$vlength), ]
# gfw_clear <-  gfw_clear[!is.na(gfw_clear$vessel_name), ]

gfwx <- read_xlsx("GFW_Vessel_info.xlsx")
gfwx[gfwx$MMSI == 247222320,]$vessel_name <- "MP LEDO"
gfwx[gfwx$MMSI == 247045120,]$vessel_name <- "ARINA MADRE"
gfwx_clear <-  gfwx[!is.na(gfwx$vlength), ]

landing <- read.csv("landing_CS.csv",sep =",")[,-1]
names(landing)[names(landing) == "vlenght"] <- "vlength"
# port <- read.csv("port_CS_PS_GFW.csv",sep=",")
port <- read_xlsx("port_CS_OTB_GFW.xlsx")
# economicdata <- read.csv("df_disaggregate/Economic_data.csv",sep=",")

# compute all weight fish landing independent of species for each cell grouped by quarter and length of unknown vessel
landing <- landing %>% group_by(id,year,gear,quarter,vlength) %>% 
  mutate(all_fish_weight = sum(tot_fish_weight))

gfwx_clear <- gfwx_clear %>% group_by(id,year,quarter,vlength) %>%
  mutate(totGFW_Fish_hours = sum(GFW_Fish_hours))

# merge dataset with information on vessels (gfw_clear) and landing information (landing)
df <- gfwx_clear %>% left_join(landing, by = c("id","year","quarter","vlength"))

# compute the total of hours spent fishing by vessels of same vessel length category
# then the total of weight that each vessel length category has collected in one hour
# in each grid, grouped by year and quarter
df <- df %>% group_by(id,year,gear,quarter,vlength) %>% 
  mutate(fish_weight_hour = (all_fish_weight/totGFW_Fish_hours))

# compute the weight fish per capita of the individual vessel (identified by vessel_name)
df <- df %>% group_by(id,year,gear, quarter,vessel_name) %>%
  mutate(pc_weight_fish = (fish_weight_hour * GFW_Fish_hours))


df %>% 
  filter(!is.na(pc_weight_fish)) %>%
  ggplot( aes(x = id, y = vessel_name, fill = pc_weight_fish)) +
  geom_tile(color = "black") +
  scale_fill_gradient(low = "blue", high = "red") + 
  geom_text(aes(label = round(pc_weight_fish)), color = "white", size = 4) + 
  facet_wrap(~ quarter, scales = "free_y") + 
  theme_bw()
ggsave("hmp.jpg", width = 15, height = 10)

plotly::ggplotly(pl)

