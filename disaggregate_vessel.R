library(dplyr)

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/surimi_irpps/")

effortcd <- read.csv("df_disaggregate/effort_CS_by_id.csv",sep =",")[,-1]
gfw <- read.csv("df_disaggregate/GFW_Vessel_info.csv",sep =",")[,-1]
names(gfw)[names(gfw) == "Vessel.Name"] <- "vessel_name"
gfw_clear <-  gfw[!is.na(gfw$vlength), ]
landing <- read.csv("df_disaggregate/landing_CS_by_id.csv",sep =",")[,-1]
names(landing)[names(landing) == "vlenght"] <- "vlength"
port <- read.csv("df_disaggregate/port_CS_PS_GFW.csv",sep=",")[,-1]
economicdata <- read.csv("df_disaggregate/Economic_data.csv",sep=",")[,-1]

port_filtered <- port %>% filter(vessel_name %in% gfw_clear$vessel_name)

gfw_clear_matchport <- gfw_clear %>% left_join(port_filtered, by = "vessel_name")

landing <- landing %>% group_by(id,year,gear,quarter,vlength) %>% 
  mutate(all_fish_weight = sum(tot_fish_weight))

df <- gfw_clear %>% left_join(landing, by = c("id","year","quarter","vlength"))

df <- df %>% group_by(id,year,gear,quarter,vlength) %>% 
  mutate(totGFW_Fish_hours = sum(GFW_Fish_hours)) %>%
  mutate(fish_weight_hour = (all_fish_weight/totGFW_Fish_hours))

df <- df %>% group_by(id,year,quarter,vessel_name) %>%
  mutate(pc_weight_fish = fish_weight_hour * GFW_Fish_hours)

# test

sum(effortcd[effortcd$id == "07F2" & effortcd$quarter == 2,]$tot_fish_day)
sum(landing[landing$id == "07F2" & landing$quarter == 2,]$tot_fish_weight)