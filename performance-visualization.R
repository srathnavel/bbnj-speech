## model performance visualization

## load packages
library(tidyverse)
library(sf)
library(tigris)
library(rnaturalearth)
library(tidymodels)
library(textrecipes)

## load data
load("data/setup.rda")
load("results/kknn_tuned.rda")
load("results/rf_tuned.rda")
load("results/linear_tuned.rda")
load("results/performance.rda")

## variable importance plot
var_plot <- rf_spec_final %>% 
  set_engine("ranger", importance = "permutation") %>% 
  fit(index ~., data = juice(prep(bbnj_rec))) %>% 
  vip::vip(geom = "point", num_features = 50)

## mapping error

error_index <- ohi_preds %>%
  mutate(error_mod = sqrt((index - .pred)^2)) %>%
  mutate(error_dir = index - .pred)

world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  select(name,
         economy,
         income_grp,
         continent,
         subregion,
         geometry)

error_map <- error_index %>%
  left_join(world, by = c("delegation" = "name"))

error_mapping <- ggplot() +
  geom_sf(data = world) +
  geom_sf(data = error_map, aes(geometry = geometry, fill = error_mod)) +
  scale_fill_gradient(low = "green", high = "blue")

save(var_plot, error_mapping, file = "results/plots.rda")
