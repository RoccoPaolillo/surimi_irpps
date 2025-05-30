library(dplyr)
library(ggplot2)
library(readxl)

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/surimi_irpps/catalan_coast/")

# upload dataset
effortcd <- read.csv("effort_CS_by_id.csv",sep =",")[,-1]
gfw <- read.csv("GFW_Vessel_info.csv",sep =",")[,-1]
names(gfw)[names(gfw) == "Vessel.Name"] <- "vessel_name"
gfw_clear <-  gfw[!is.na(gfw$vlength), ]
# gfw_clear <-  gfw_clear[!is.na(gfw_clear$vessel_name), ]

landing <- read.csv("landing_CS_by_id.csv",sep =",")[,-1]
names(landing)[names(landing) == "vlenght"] <- "vlength"
port <- read.csv("port_CS_PS_GFW.csv")[,-1]

# compute all weight fish landing independent of species for each cell grouped by quarter and length of unknown vessels
landing_dis <- landing  %>% group_by(id,year,quarter,vlength) %>% 
  mutate(all_fish_weight = sum(tot_fish_weight))

landing_dis <- landing_dis %>% select(id,year, quarter, vlength,all_fish_weight)
landing_dis <- landing_dis[!duplicated(landing_dis),]

gfw_clear <- gfw_clear %>% group_by(id,year,quarter,vlength) %>%
  mutate(totGFW_Fish_hours = sum(GFW_Fish_hours))

# merge dataset with information on vessels (gfw_clear) and landing information (landing)
df <- gfw_clear %>% left_join(landing_dis, by = c("id","year","quarter","vlength"))

# compute the total of hours spent fishing by vessels of same vessel length category
# then the total of weight that each vessel length category has collected in one hour
# in each grid, grouped by year and quarter
df <- df %>% group_by(id,year,quarter,vlength) %>% 
  mutate(fish_weight_hour = (all_fish_weight/totGFW_Fish_hours))

# compute the weight fish per capita of the individual vessel (identified by vessel_name)
df <- df %>% group_by(id,year, quarter,vessel_name) %>%
  mutate(pc_weight_fish = (fish_weight_hour * GFW_Fish_hours))


df %>% 
#  filter(!is.na(pc_weight_fish)) %>%
  ggplot( aes(x = id, y = vessel_name, fill = pc_weight_fish)) +
  geom_tile(color = "black") +
  scale_fill_gradient(low = "blue", high = "red") + 
  geom_text(aes(label = round(pc_weight_fish)), color = "white", size = 4) + 
  facet_wrap(~ quarter, scales = "free_y") + 
  theme_bw()
ggsave("hmp.jpg", width = 15, height = 10)

# verification: we take the computed cumulative data in df and compare with target cumulative data in landing
# we group by id cell, year and quarter

vessel_fish <- df %>% group_by(id,year,quarter,vlength) %>% mutate(tot_fish_vessel = sum(pc_weight_fish)) %>%
  select(id,year,quarter,vlength,tot_fish_vessel)
# there are duplicated because this is the sum reported for each vessel of group(id, year, quarter)
vessel_fish <- vessel_fish[!duplicated(vessel_fish),]

landing_fish <- landing %>% group_by(id,year,quarter,vlength) %>% mutate(tot_fish_landing = sum(tot_fish_weight)) %>%
  select(id,year,quarter,vlength,tot_fish_landing)


vessel_fish_unique <- vessel_fish[!is.na(vessel_fish$tot_fish_vessel), ]
landing_fish_unique <- landing_fish[!duplicated(landing_fish),]

dfv <- vessel_fish_unique  %>% left_join(landing_fish_unique, by = c("id","year","vlength","quarter"))

dfv %>% ggplot(aes(x = tot_fish_vessel, y = tot_fish_landing)) +
  geom_point() + 
  geom_abline(slope = 1, intercept = 0, color = "red") +
  xlab("landing computed") +
  ylab("landing target") +
  theme_bw()
ggsave("verification.jpg", width = 10, height = 5)
