library(dplyr)

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/surimi_irpps/")

# upload dataset
effortcd <- read.csv("df_disaggregate/effort_CS_by_id.csv",sep =",")[,-1]
gfw <- read.csv("df_disaggregate/GFW_Vessel_info.csv",sep =",")[,-1]
names(gfw)[names(gfw) == "Vessel.Name"] <- "vessel_name"
gfw_clear <-  gfw[!is.na(gfw$vlength), ]
landing <- read.csv("df_disaggregate/landing_CS_by_id.csv",sep =",")[,-1]
names(landing)[names(landing) == "vlenght"] <- "vlength"
port <- read.csv("df_disaggregate/port_CS_PS_GFW.csv",sep=",")[,-1]
economicdata <- read.csv("df_disaggregate/Economic_data.csv",sep=",")[,-1]

# compute all weight fish landing independent of species for each cell grouped by quarter and length of unknown vessel
landing <- landing %>% group_by(id,year,gear,quarter,vlength) %>% 
  mutate(all_fish_weight = sum(tot_fish_weight))

gfw_clear <- gfw_clear %>% group_by(id,year,quarter,vlength) %>%
  mutate(totGFW_Fish_hours = sum(GFW_Fish_hours))

# merge dataset with information on vessels (gfw_clear) and landing information (landing)
df <- gfw_clear %>% left_join(landing, by = c("id","year","quarter","vlength"))

# compute the total of hours spent fishing by vessels of same vessel length category
# then the total of weight that each vessel length category has collected in one hour
# in each grid, grouped by year and quarter
df <- df %>% group_by(id,year,gear,quarter,vlength) %>% 
  mutate(fish_weight_hour = (all_fish_weight/totGFW_Fish_hours))

# compute the weight fish per capita of the individual vessel (identified by vessel_name)
df <- df %>% group_by(id,year,quarter,vessel_name) %>%
  mutate(pc_weight_fish = (fish_weight_hour * GFW_Fish_hours))

# extra: ports associated with vessels not NA and match not NA vessels and ports (23 vessels) 
port_filtered <- port %>% filter(vessel_name %in% gfw_clear$vessel_name)
gfw_clear_matchport <- gfw_clear %>% left_join(port_filtered, by = "vessel_name")