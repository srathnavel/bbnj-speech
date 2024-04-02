## random forest

## load packages
library(tidymodels)
library(tidyverse)
library(textrecipes)

tidymodels_prefer()

## load data
load("data/02_tidy_data/setup.rds")

## model spec
rf_spec <-
  rand_forest(mtry = tune(), min_n = tune()) %>%
  set_engine('ranger') %>%
  set_mode('regression')

## model workflow
rf_workflow <- workflow() %>%
  add_model(rf_spec) %>%
  add_recipe(bbnj_rec)

## tuning parameters
rf_params <- extract_parameter_set_dials(rf_workflow) %>%
  update(mtry = mtry(c(1, 20)))

rf_grid <- grid_regular(rf_params, levels = 5)

## tuning model
rf_tuned <- tune_grid(
  rf_workflow,
  bbnj_folds,
  grid = rf_grid,
  control = tune_controls)

## save results
save(rf_tuned, file = "results/01_model_output/rf_tuned.rds")