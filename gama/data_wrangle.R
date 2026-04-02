setwd("C:/Users/LENOVO/Gama_Workspace/surimi/includes/smart5km")

library(dplyr)
library(sf)
library(tidyr)

df <- read.csv("vessel_by_port.csv",sep=",")
b <- df %>% group_by(MMSI,vlength) %>% distinct(MMSI,vlength)

dfp <- read.csv("vessel_by_cell.csv",sep=",")
a <- dfp %>% group_by(MMSI,vlength) %>% distinct(MMSI,vlength)

# to merge only df vessel and add gear
dfp_noid <- dfp %>% distinct(MMSI,vlength,gear)
  
fin <- left_join(df,dfp_noid, by=c("MMSI","vlength"))

spe <- read.csv("spe_by_port.csv",sep=",")

effort_cell <- read.csv("effort_by_cell.csv",sep=",")

write.csv(fin,file="combined_vessel.csv",row.names = F)

# shape <- st_read("SMART_Data/IBM.agg.grid.shp")
# tapply(shape$CFR, shape$harbour, function(x) length(unique(x)))
# 
# 
# 
# shape %>%
#   group_by(CFR) %>%
#   summarise(
#     n_harbour = n_distinct(harbour),
#     .groups = "drop"
#   ) %>%
#   filter(n_harbour > 1)
# 
# shape$harbour[shape$CFR == "boat_23" & is.na(shape$harbour)] <- "PORTO SANTO STEFANO"
# shape <- st_zm(shape, drop = TRUE, what = "ZM")
# st_write(shape, "SMART_Data/IBM.agg.grid_RP.shp")
shape %>%
  group_by(CFR) %>%
  summarise(
    n_Gear = n_distinct(Gear),
    .groups = "drop"
  ) %>%
  filter(n_Gear > 1)
##
shape <- st_read("IBM_grid5km.shp")
shape_filtered <- shape %>% select(id, CFR, MONTH, Gear, VL, harbour, depth, fishday, geometry) %>%
  group_by(id) %>%
  mutate(avg_depth = mean(depth)) %>%
  select(-depth)

# df_flagged <- shape_filtered %>%
#   group_by(id, CFR, VL, MONTH) %>%
#   mutate(fishday_consistent = n_distinct(fishday) == 1) %>%
#   ungroup()

shape_filtered <- distinct(shape_filtered %>% st_drop_geometry()) 

shape_cleaned <- unique(shape %>% select(id,geometry))

shape_filtered <- left_join(shape_filtered,shape_cleaned,by = "id")
# shape_filtered <- shape_filtered %>% select(-avg_depth)
shapefile_shape <- st_as_sf(shape_filtered, crs = st_crs(shape))

write_sf(shapefile_shape, "sub_shape5km_new.shp")



write.csv(shape_filtered,file = "sub_shape5km.csv")
# write_sf(sub_shape, "sub_shape5km.shp")

grid5km <- st_read("grid5km.shp")


grid <- st_read("grid_sf.shp")


shape_byspecies <- shape %>%
  group_by(id, Species) %>%
  mutate(W_mean_sum = sum(W_mean, na.rm = TRUE)) %>%
  ungroup() %>%
  pivot_wider(
    names_from  = Species,
    values_from = W_mean_sum,
    names_glue  = "{Species}_W_mean"
  ) 

shape <- as.data.frame(shape)
shape_byspecies <- as.data.frame(shape_byspecies)

shapefin <- merge(shape, shape_byspecies, by = c("CFR","id","MONTH","Gear","VL","harbour","effrt_m",
                                                 "lpue_mn","Pric_mn","GVL_men","depth","geometry","W_mean"), all.x = TRUE) 

shapefin <- shapefin %>% select(id, MUT_W_mean, OCC_W_mean, HOM_W_mean, RJC_W_mean, EDT_W_mean, HKE_W_mean, RJO_W_mean, MON_W_mean, MTS_W_mean, 
MUR_W_mean, EOI_W_mean, SQM_W_mean, DPS_W_mean, SDV_W_mean, JRS_W_mean, SYC_W_mean, JAI_W_mean, CTC_W_mean, ARS_W_mean, NEP_W_mean, ARA_W_mean, QUB_W_mean)

names(shapefin) <- trimws(names(shapefin))

shapefin_wide <- shapefin %>%
  group_by(id) %>%
  summarise(
    dplyr::across(
      .cols = dplyr::all_of(setdiff(names(shapefin), "id_grid")),
      .fns  = ~ {
        v <- unique(na.omit(.x))
        if (length(v) == 0) NA_real_ else v[1]
      }
    ),
    .groups = "drop"
  )

cols_to_check <- setdiff(names(shapefin), "id_grid")

check_unique <- shapefin %>%
  group_by(id_grid) %>%
  summarise(
    across(
      all_of(cols_to_check),
      ~ n_distinct(.x, na.rm = TRUE)
    ),
    .groups = "drop"
  )

# grids where ANY column has >1 distinct non-NA value
violations <- check_unique %>%
  filter(if_any(all_of(cols_to_check), ~ .x > 1))

violations

grid <- as.data.frame(grid)
grid_rp <- left_join(grid,shapefin_wide,by="id_grid")

# grid_rp <- st_as_sf(grid_rp)
# grid_rp <- st_zm(grid_rp, drop = TRUE, what = "ZM")
# st_write(grid_rp, "SMART_Data/grid_rp.shp")

nogrid <- grid %>% filter(id_grid %in% shapefin$id_grid)
length(unique(shapefin$id_grid))

unique(shapefin$W_mean.x != shapefin$W_mean.y)

#####


