## model setup

## load packages
library(tidyverse)
library(tidymodels)
library(tidytext)
library(textrecipes)

## load data
load("data/bbnj_dat.rda")

## splitting
set.seed(820)

bbnj_split <- bbnj_dat %>%
 initial_split(prop = 0.7, strata = delegation)

bbnj_train <- bbnj_split %>%
  training()
bbnj_test <- bbnj_split %>%
  testing()

# cross fold validation
bbnj_folds <- vfold_cv(bbnj_train, v = 5, repeats = 3, strata = delegation)

tune_controls <- control_resamples(verbose = TRUE)

## recipe
bbnj_rec <- recipe(index ~ lemmas, data = bbnj_train) %>%
  step_tokenize(lemmas, token = "ngrams") %>% 
  step_tokenfilter(lemmas, min_times = 10, max_tokens = 100) %>% 
  step_tfidf(lemmas)

save(bbnj_rec, bbnj_folds, bbnj_train, bbnj_test, tune_controls, file = "data/setup.rda")
