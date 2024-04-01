## model evaluation

## libraries
library(tidyverse)
library(tidymodels)
library(textrecipes)

## load data
load("data/setup.rda")

## load tuned objects
load("results/kknn_tuned.rda")
load("results/rf_tuned.rda")
load("results/linear_tuned.rda")


## looking at metrics
collect_metrics(kknn_tuned)
collect_metrics(rf_tuned)
collect_metrics(linear_tuned)

## fitting the best model by rmse (rf with mtry 1 and min_n 2)
rf_spec_final <-
  rand_forest(mtry = 1, min_n = 2) %>%
  set_engine('ranger') %>%
  set_mode('regression')

rf_workflow_final <- workflow() %>%
  add_model(rf_spec_final) %>%
  add_recipe(bbnj_rec)

## fit to training set
rf_fit <- fit(rf_workflow_final, bbnj_train)

## predict on test set

ohi_preds <- predict(rf_fit, new_data = bbnj_test) %>%
  bind_cols(bbnj_test %>% select(delegation, index))

rmse(ohi_preds, estimate = .pred, truth = index)

## 
save(rf_spec_final, ohi_preds, file = "results/performance.rda")
