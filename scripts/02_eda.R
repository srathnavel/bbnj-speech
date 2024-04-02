## visualizations

## load packages
library(tidyverse)
library(tidymodels)
library(ggplot2)
library(wordcloud)
library(tidytext)
library(rnaturalearth)

## load data
load("data/02_tidy_data/bbnj_dat.rda")
load("data/ohi.rda")

## splitting
set.seed(820)

bbnj_split <- bbnj_dat %>%
  initial_split(prop = 0.8, strata = delegation)

bbnj_train <- bbnj_split %>%
  training()

## find distribution of index
ggplot(bbnj_train, aes(x = index)) +
  geom_density()

quantile(bbnj_train$index)

## spatial distribution of index

world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  select(name,
         economy,
         income_grp,
         continent,
         subregion,
         geometry)

## all countries

index_world <- ohi %>%
  select(region_name, index) %>%
  unique() %>%
  left_join(world, by = c("region_name" = "name"))

index_map <- ggplot() +
  geom_sf(data = world) +
  geom_sf(data = index_world, aes(geometry = geometry, fill = index)) +
  scale_fill_gradient(low = "green", high = "blue")

### only for countries in speech dataset

index_bbnj <- bbnj_train %>%
  select(delegation, index) %>%
  unique() %>%
  left_join(world, by = c("delegation" = "name"))

bbnj_countries_map <- ggplot() +
  geom_sf(data = world) +
  geom_sf(data = index_bbnj, aes(geometry = geometry, fill = index)) +
  scale_fill_gradient(low = "green", high = "blue")


## wordclouds

## organize data
tokenize_lemmas <- bbnj_train %>%
  unnest_tokens(words, lemmas) %>%
  count(delegation, link_text, words) %>%
  bind_tf_idf(delegation, words, n)

wordcloud_tokens <- bbnj_train %>%
  select(delegation, link_text, lemmas, index) %>%
  mutate(quartile = dplyr::ntile(index, 4)) %>%
  right_join(tokenize_lemmas, by = c("delegation", "link_text")) %>%
  mutate(quartile = as.factor(quartile))

## wordcloud for upper quartile index

cloud4 <- wordcloud_tokens %>%
  filter(quartile == "4") %>%
  select(c(words, n)) %>%
  group_by(words) %>%
  summarise(sum = sum(n, na.rm = T))

cloud4 %>%
  with(wordcloud(words, sum, max.words = 50))

cloud3 <- wordcloud_tokens %>%
  filter(quartile == "3") %>%
  select(c(words, n)) %>%
  group_by(words) %>%
  summarise(sum = sum(n, na.rm = T))

cloud3 %>%
  with(wordcloud(words, sum, max.words = 50, rot.per = 0))

cloud2 <- wordcloud_tokens %>%
  filter(quartile == "2") %>%
  select(c(words, n)) %>%
  group_by(words) %>%
  summarise(sum = sum(n, na.rm = T))

cloud2 %>%
  with(wordcloud(words, sum, max.words = 50, rot.per = 0))

cloud1 <- wordcloud_tokens %>%
  filter(quartile == "1") %>%
  select(c(words, n)) %>%
  group_by(words) %>%
  summarise(sum = sum(n, na.rm = T))

cloud1 %>%
  with(wordcloud(words, sum, max.words = 50, rot.per = 0))

save(index_map, bbnj_countries_map, cloud1, cloud2, cloud3, cloud4, file = "eda-vis.rda")       
