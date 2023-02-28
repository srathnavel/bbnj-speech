## linear regression

## load packages
library(tidymodels)
library(tidyverse)
library(textrecipes)

tidymodels_prefer()

## load data
load("data/setup.rda")

## model spec
linear_spec <-
  linear_reg(penalty = tune(), mixture = tune()) %>%
  set_engine('glmnet')

## model workflow
linear_workflow <- workflow() %>%
  add_model(linear_spec) %>%
  add_recipe(bbnj_rec)

## tuning parameters
linear_params <- extract_parameter_set_dials(linear_workflow) %>%
  update(mixture = mixture(c(0, 1)),
         penalty = penalty(c(0, 1)))

linear_grid <- grid_regular(linear_params, levels = 3)

## tuning model
linear_tuned <- tune_grid(
  linear_workflow,
  bbnj_folds,
  grid = linear_grid,
  control = tune_controls)

## save results
save(linear_tuned, file = "results/linear_tuned.rda")