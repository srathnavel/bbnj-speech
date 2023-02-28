## text processing

## load packages
library(tidyverse)
library(tidymodels)
library(tidytext)
library(spacyr)
## library(textcat)
library(cld2)
## library(cld3)
library(deeplr)
library(googleLanguageR)

tidymodels_prefer()

## load dataset from scraping.R
speech_dat <- readRDS("data/speech_dat.rds")

## general lemmatize data function (for use in lemmatize_data)
parse_tokens <- function(doc) {
  
  spacy_parse(doc, pos = TRUE, entity = FALSE) %>% 
    filter(pos %in% c("NOUN", "VERB")) %>% 
    pull(lemma) %>% 
    str_c(collapse = " ")
}

# lemmatize text column of a given data frame
lemmatize_data <- function(df) {
  spacy_initialize(model = "en_core_web_sm")
  
  out_df <- df %>% 
    group_by(text) %>% 
    mutate(lemmas = parse_tokens(text)) %>% 
    ungroup(text)
  
  spacy_finalize()
  
  return(out_df)
}

speech_lemmas <- lemmatize_data(speech_dat)

## language detection

## found cld2 more accurate than textcat and better at classifying NA than cld3
speech_lemmas <- speech_lemmas %>% 
  mutate(cld2 = cld2::detect_language(text = text, plain_text = FALSE))

speech_lemmas %>% count(cld2)
## 30 are in other languages
## 19 are blank (scraping failed)
## enough to just do english?

## tried translating
## need API authkey
# translation = list()
#          
# for (i in range(nrow(speech_lemmas))) {
#   source_lang <- speech_lemmas$cld2[i]
#   
#   translation <- append(translation, 
#                         googleLanguageR::gl_translate(speech_lemmas$lemmas[i],
#                                                       target = "en",
#                                                       source = source_lang))
# }

speech_lemmas <- speech_lemmas %>%
  filter(cld2 == "en")

## wanted to check for country names
## named entity extraction

spacyr::spacy_initialize()
spacyr::spacy_extract_entity(bbnj_dat$lemmas) %>%
  filter(ent_type == "GPE")
spacyr::spacy_finalize()

save(speech_lemmas, file = "data/speech_lemmas.rda")
