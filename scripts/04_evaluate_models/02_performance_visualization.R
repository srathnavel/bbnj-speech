## model performance visualization

## load packages
library(tidyverse)
library(sf)
library(tigris)
library(rnaturalearth)
library(tidymodels)
library(textrecipes)

## load data
load("data/02_tidy_data/setup.rds")

## load tuned objects
load("results/01_model_output/kknn_tuned.rds")
load("results/01_model_output/rf_tuned.rds")
load("results/01_model_output/linear_tuned.rds")

## load test performance
load("results/02_performance/performance.rds")

## variable importance plot
rf_spec_final %>% 
  set_engine("ranger", importance = "permutation") %>% 
  fit(index ~., data = juice(prep(bbnj_rec))) %>% 
  vip::vi() %>%
  mutate(Variable = str_remove(Variable, "tfidf_lemmas_"))

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
  right_join(world, by = c("delegation" = "name"))

error_mapping <- ggplot() +
  #geom_sf(data = world) +
  geom_sf(data = error_map, aes(geometry = geometry, fill = error_mod)) +
  scale_fill_gradient(low = "green", high = "blue") +
  theme_void()

save(var_plot, error_map, file = "results/02_performance/plots.rds")
