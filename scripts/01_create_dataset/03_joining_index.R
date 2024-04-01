## prepare dataset

## load packages
library(tidyverse)
library(tidymodels)

## load data
 
load("data/speech_lemmas.rds")

speech_lemmas %>%
  count(delegation) %>%
  View()

ohi <- read_csv("data/ohi_scores.csv") %>%
  mutate(year = as.numeric(scenario)) %>%
  filter(year == 2022) %>%
  filter(!str_detect(long_goal, "(subgoal)")) %>%
  dplyr::select(-c(scenario, dimension, long_goal, year)) %>%
  group_by(region_name, goal) %>%
  summarize(value = mean(value, na.rm = TRUE)) %>%
  # dplyr::na_if("NaN") %>%
  pivot_wider(names_from = "goal", values_from = "value") %>%
  janitor::clean_names() 

read_csv("data/ohi_scores.csv") %>%
  select(goal, long_goal) %>%
  distinct()

save(ohi, file = "data/ohi.rda")

speech_lemmas <- speech_lemmas %>% 
  select(delegation, link_text, lemmas)

bbnj_dat <- left_join(speech_lemmas, ohi, 
                      by = c("delegation" = "region_name")) %>%
  filter(!is.na(index))

## only 40 unique countries 
# all %>%
#   count(delegation)

save(bbnj_dat, goals, file = "data/bbnj_dat.rda")
