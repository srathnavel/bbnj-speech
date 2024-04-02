## model setup

## load packages
library(tidyverse)
library(tidymodels)
library(tidytext)
library(textrecipes)

## load data
load("data/02_tidy_data/bbnj_dat.rds")

## splitting data
set.seed(820)

bbnj_split <- bbnj_dat %>%
 initial_split(prop = 0.7, strata = delegation)

### train models on 70% of the data
bbnj_train <- bbnj_split %>%
  training()

### reserve 30% to test models
bbnj_test <- bbnj_split %>%
  testing()

## cross fold validation
bbnj_folds <- vfold_cv(bbnj_train, v = 5, repeats = 3, strata = delegation)

tune_controls <- control_resamples(verbose = TRUE)

## recipe

### predict ocean health index using speech contents
bbnj_rec <- recipe(index ~ lemmas, data = bbnj_train) %>%
  ### try ngrams
  step_tokenize(lemmas, token = "ngrams") %>% 
  ### limit predictors based oncounts and frequency
  step_tokenfilter(lemmas, min_times = 10, max_tokens = 100) %>% 
  ### compute tf-idf score for each lemma
  step_tfidf(lemmas)

save(bbnj_rec, bbnj_folds, bbnj_train, bbnj_test, tune_controls, file = "data/02_tidy_data/setup.rds")
