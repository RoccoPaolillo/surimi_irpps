library(dplyr)
library(ggplot2)
library(readxl)

setwd("C:/Users/rocpa/OneDrive/Documenti/GitHub/surimi_irpps/GSA9")

# upload dataset
effortcd <- read.csv("effort_CS.csv",sep =",")[,-1]
# gfw <- read.csv("GFW_Vessel_info.csv",sep =",")[,-1]
# names(gfw)[names(gfw) == "Vessel.Name"] <- "vessel_name"
# gfw[gfw$MMSI == 247222320,]$vessel_name <- "MP LEDO"
# gfw[gfw$MMSI == 247045120,]$vessel_name <- "ARINA MADRE"
# gfw_clear <-  gfw[!is.na(gfw$vlength), ]
# gfw_clear <-  gfw_clear[!is.na(gfw_clear$vessel_name), ]

gfwx <- read_xlsx("GFW_Vessel_info.xlsx")
gfwx[gfwx$MMSI == 247222320,]$vessel_name <- "MP LEDO"
gfwx[gfwx$MMSI == 247045120,]$vessel_name <- "ARINA MADRE"
gfwx_clear <-  gfwx[!is.na(gfwx$vlength), ]
gfwx_clear <-  gfwx_clear[! duplicated(gfwx_clear),]

landing <- read.csv("landing_CS.csv",sep =",")[,-1]
names(landing)[names(landing) == "vlenght"] <- "vlength"
# port <- read.csv("port_CS_PS_GFW.csv",sep=",")
port <- read_xlsx("vessel_info_rev.xlsx")
port <- port[!duplicated(port),]

# compute all weight fish landing independent of species for each cell grouped by quarter and length of unknown vessels
landing_dis <- landing %>% group_by(id,year,quarter,vlength) %>% 
  mutate(all_fish_weight = sum(tot_fish_weight))

landing_dis <- landing_dis %>% select(id,year, quarter, vlength,all_fish_weight)
landing_dis <- landing_dis[!duplicated(landing_dis),]

gfwx_clear <- gfwx_clear %>% group_by(id,year,quarter,vlength) %>%
  mutate(totGFW_Fish_hours = sum(GFW_Fish_hours))

# merge dataset with information on vessels (gfw_clear) and landing information (landing)
df <- gfwx_clear %>% left_join(landing_dis, by = c("id","year","quarter","vlength"))

# compute the total of hours spent fishing by vessels of same vessel length category
# then the total of weight that each vessel length category has collected in one hour
# in each grid, grouped by year and quarter
df <- df %>% group_by(id,year,quarter,vlength) %>% 
  mutate(fish_weight_hour = (all_fish_weight/totGFW_Fish_hours))

# compute the weight fish per capita of the individual vessel (identified by vessel_name)
df <- df %>% group_by(id,year, quarter,vlength, vessel_name) %>%
  mutate(pc_weight_fish = (fish_weight_hour * GFW_Fish_hours))


df %>% 
#  filter(!is.na(pc_weight_fish)) %>%
  ggplot( aes(x = id, y = vessel_name, fill = pc_weight_fish)) +
  geom_tile(color = "black") +
  scale_fill_gradient(low = "blue", high = "red") + 
  geom_text(aes(label = round(pc_weight_fish, 2)), color = "white", size = 2) + 
  facet_wrap(~ quarter, scales = "free_y") + 
  theme_bw()
ggsave("hmp.jpg", width = 17, height = 13)

# verification: we take the computed cumulative data in df and compare with target cumulative data in landing
# we group by id cell, year and quarter

vessel_fish <- df %>% group_by(id,year,quarter,vlength) %>% mutate(tot_fish_vessel = sum(pc_weight_fish)) %>%
  select(id,year,quarter,vlength,tot_fish_vessel)
# there are duplicated because this is the sum reported for each vessel of group(id, year, quarter)
vessel_fish <- vessel_fish[!duplicated(vessel_fish),]

landing_fish <- landing %>% group_by(id,year,quarter,vlength) %>% mutate(tot_fish = sum(tot_fish_weight)) %>%
  select(id,year,quarter,vlength,tot_fish)


vessel_fish_unique <- vessel_fish[!is.na(vessel_fish$tot_fish_vessel), ]
landing_fish_unique <- landing_fish[!duplicated(landing_fish),]

dfv <- vessel_fish_unique  %>% left_join(landing_fish_unique, by = c("id","year","vlength","quarter"))

dfv %>% ggplot(aes(x = tot_fish_vessel, y = tot_fish)) +
  geom_point() + 
  geom_abline(slope = 1, intercept = 0, color = "red") +
  xlab("landing computed") +
  ylab("landing target") +
  theme_bw()
ggsave("verification.jpg", width = 10, height = 5)

# merging ports def

df_portdef <- df  %>% left_join(port, by = c("MMSI","vessel_name","vlength"))
names(df_portdef)[names(df_portdef) == "port_def"] <- "port_defOLD"

# plots

# this is to report in the name of vessels its length
df_portdef$vessel_length <- paste0(df_portdef$vessel_name," ", df_portdef$vlength)

# to get how much each vessel bring to the port they are associated to from each grid 
# Portovenere has one vessel with NA fishlanding associated, NA from ports with no vessel matched
for (i in unique(df_portdef$Port_DEF)[! unique(df_portdef$Port_DEF) %in% c(NA,"PORTOVENERE")]) {
  
df_portdef %>% filter(Port_DEF == i) %>%
     filter(!is.na(vessel_name), !is.na(id), !is.na(pc_weight_fish)) %>%
ggplot(aes(x = vessel_length, y = pc_weight_fish, fill = id)) +
         geom_col() +
  labs(x = "Vessel Name", y = "Landing per vessel", fill = "Cell\norigin",
  title = i) + 
  facet_wrap(~quarter) +
  coord_flip() +
  theme_bw()
  ggsave(paste0(i,".jpg"), width = 8, height = 7)
}

# landing from grid to port
df_portnow <- df_portdef %>% 
  filter(!is.na(id), !is.na(Port_DEF)) %>%
  group_by(id,quarter,Port_DEF) %>%
  mutate(total_pcweightfish = sum(pc_weight_fish)) %>%
  select(id,Port_DEF,total_pcweightfish)
df_portnow <- df_portnow[!duplicated(df_portnow),]
df_portnow %>%
  ggplot( aes(x = id, y = Port_DEF, fill = total_pcweightfish)) +
  geom_tile(color = "black") +
  scale_fill_gradient(low = "blue", high = "red") + 
  labs(x = "Cell origin",y = "Port", fill = "Landing\nby vessels") + 
  facet_wrap(~ quarter) + 
  theme_bw() +
  theme(axis.text.x = element_text(hjust = 1, angle = 45))
ggsave("hmp_port.jpg", width = 12, height = 8)

# landing from grid by length of vessels
df_portlength <- df_portdef %>%
  group_by(id,quarter,vlength) %>%
  mutate(total_pcwlength = sum(pc_weight_fish)) %>%
  select(id,vlength,total_pcwlength)
df_portlength <- df_portlength[!duplicated(df_portlength),]
  
df_portlength %>%
  ggplot(aes(x = id, y = vlength, fill = total_pcwlength))+
  geom_tile(color = "black") +
  scale_fill_gradient(low = "blue", high = "red")+
  labs(x = "Cell origin",y = "Length vessels", fill = "Landing\nby length") +
  facet_wrap(~ quarter) +
  theme_bw() +
  theme(axis.text.x = element_text(hjust = 1, angle = 45))
ggsave("hmp_lenght.jpg", width = 10, height = 6)

# fish hours by length
dflength <- df_portdef %>%
  group_by(id,quarter,vlength) %>%
  mutate(total_hours = sum(GFW_Fish_hours)) %>%
  select(id,quarter,vlength,total_hours)
dflength <- dflength[!duplicated(dflength),]

dflength %>%
  ggplot(aes(x = id, y = total_hours, fill =  vlength)) +
  geom_col() + 
  facet_wrap(~ quarter) + 
  labs(x = "Cell origin",y = "Fish hours", fill = "Vessels\nlength") +
  theme_bw()+
  theme(axis.text.x = element_text(hjust = 1, angle = 45))
ggsave("hours_lenght.jpg", width = 10, height = 6)

# count vessel length
countsample <- df_portdef[!duplicated(df_portdef$vessel_name),]
countsample <- countsample %>% filter(!is.na(id), !is.na(Port_DEF)) %>% 
  filter(!is.na(vessel_name), !is.na(id), !is.na(pc_weight_fish))
ggplot(countsample, aes(vlength)) + geom_bar() +
  labs(x = "Vessels Lenght",y = "Count Vessels") +
  theme_bw()
ggsave("count_vessels.jpg", width = 10, height = 5)


# Sankey diagram
install.packages("ggalluvial")
library(ggalluvial)

ggplot(data = df_portdef[df_portdef$Port_DEF == "ANZIO",],
       aes(axis1 = id, axis2 = Port_DEF, y = pc_weight_fish)) +
  geom_alluvium(aes(fill = vessel_name)) +
  geom_stratum() +
  geom_text(stat = "stratum",
            aes(label = after_stat(stratum))) +
  facet_wrap(~ quarter, dir = "v") + 
  scale_x_discrete(limits = c("id", "Port_DEF"),
                   expand = c(0.15, 0.05)) +
  theme_void()






