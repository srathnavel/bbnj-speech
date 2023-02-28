## bbnj web scraping script

## load packages
library(tidyverse)
library(here)
library(magrittr)
library(rvest)
library(purrr)
library(pdftools)

## read in webpages
page1 <- rvest::read_html("https://www.un.org/bbnj/statements-first-session")
page2 <- rvest::read_html("https://www.un.org/bbnj/statements-second-session")
page3 <- rvest::read_html("https://www.un.org/bbnj/statements-third-session")
page4 <- rvest::read_html("https://www.un.org/bbnj/statements")
page5 <- rvest::read_html("https://www.un.org/bbnj/statements-fifth-session")

pages <- list(page1, page2, page3, page4, page5)

## scraping tables

## dataset to be populated
speaker_data <- data.frame("delegation" = vector(mode = "character", length = 0),
                           "date" = vector(mode = "character", length = 0),
                           "link_text" = vector(mode = "character", length = 0),
                           "link" = vector(mode = "character", length = 0))

## extract tables
for (page in pages) {
  
  link_nodes <- page %>% html_nodes(xpath = "//table//a")  
  link_text  <- link_nodes %>% html_text()

  delegation <- link_nodes %>% 
    ## find 2 columns before
    ## ancestor to ignore inconsistent <p> wrapping
    html_elements(xpath = "//table//a/ancestor::td/preceding-sibling::td[2]") %>%
    html_text()
  
  date <- link_nodes %>% 
    ## find 1 column before
    html_elements(xpath = "//table//a/ancestor::td/preceding-sibling::td[1]") %>%
    html_text()
  
  df <- tibble(delegation = delegation, 
               date = date,
               link_text = link_nodes %>% html_text(),
               link = link_nodes %>% html_attr("href"))
  
  speaker_data <- bind_rows(speaker_data, df)
  
}

## scraping pdf files

## dataset to be populated
speech_data <- data.frame(matrix(ncol = 2, nrow = 0))
colnames(speech_data) <- c('speaker', 'text')

## function to read text into dataset

for (i in list(speaker_data$link)) {
  ## create and name directory
  pdf_dir <- here(paste0("temp/"))
  dir.create(pdf_dir)
  
  ## download files to directory
  raw_list <- i %>%
    walk2(.,
          paste0(pdf_dir, 
                 "/" ,
                 "bbnj_",
                 (str_remove(., "https://www.un.org/bbnj/sites/www.un.org.bbnj/files/")) 
          ),
          download.file, mode = "wb")
  
  ## vector of downloaded files
  files <- list.files(here("temp"), pattern = "\\.pdf$")
  ## add directory to each file name
  files_dir <- paste("temp/", files, sep = "")
  ## count number of files
  n_speeches <- length(files)
  
  ## add speaker and text for each pdf file
  for (i in 1:n_speeches) {
    text <- paste(pdf_text(files_dir[i]), collapse = " ")
    link <- files_dir[i]
    
    speech_data[nrow(speech_data) + 1, ] <- c(link, text)
  }
  
  ## remove directory and files
  unlink(pdf_dir, recursive = TRUE)
  
}

## make link naming consistent
#### undoing naming step in pdf download function
speech_data$speaker <- speech_data$speaker %>%
  str_replace(pattern = "temp/bbnj_", 
              replacement = "https://www.un.org/bbnj/sites/www.un.org.bbnj/files/")

## join table and pdf text datasets to create final dataset
speech_dat <- left_join(speaker_data, speech_data, by = c("link" = "speaker"))

## save to rds
saveRDS(speech_dat, file = "data/speech_dat.rds")

## helpful sources
#### https://oceanhealthindex.org/news/scraping_webpages_and_pdfs/
#### https://stackoverflow.com/questions/63093926/retrieve-link-from-html-table-with-rvest
