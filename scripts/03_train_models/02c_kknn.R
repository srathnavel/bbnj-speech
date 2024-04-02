## k-nearest neighbors

## load packages
library(tidymodels)
library(tidyverse)
library(textrecipes)

tidymodels_prefer()

## load data
load("data/02_tidy_data/setup.rds")

## model spec
kknn_spec <-
  nearest_neighbor(neighbors = tune()) %>%
  set_engine('kknn') %>%
  set_mode('regression')

## model workflow
kknn_workflow <- workflow() %>%
  add_model(kknn_spec) %>%
  add_recipe(bbnj_rec)

## tuning parameters
kknn_params <- extract_parameter_set_dials(kknn_workflow) %>%
  update(neighbors = neighbors(c(15, 25)))

kknn_grid <- grid_regular(kknn_params, levels = 5)

## tuning model
kknn_tuned <- tune_grid(
  kknn_workflow,
  bbnj_folds,
  grid = kknn_grid,
  control = tune_controls)

## save results
save(kknn_tuned, file = "results/01_model_output/kknn_tuned.rds")
