## bbnj web scraping script

## load packages
library(tidyverse)
library(here)
library(rvest)
library(pdftools)

#### scrape tables to get pdf links ####

## read in webpages
page1 <- read_html("https://www.un.org/bbnj/statements-first-session")
page2 <- read_html("https://www.un.org/bbnj/statements-second-session")
page3 <- read_html("https://www.un.org/bbnj/statements-third-session")
page4 <- read_html("https://www.un.org/bbnj/statements")
page5 <- read_html("https://www.un.org/bbnj/statements-fifth-session")

pages <- list(page1, page2, page3, page4, page5)

## empty dataframe to populate
speaker_data <- data.frame()

## extract tables
for (page in pages) {
  
  ## find all nodes with a link
  link_nodes <- page %>% html_nodes(xpath = "//table//a")  
  link_text  <- link_nodes %>% html_text()
  
  delegation <- link_nodes %>% 
    ## find the text in the cell 2 columns before each link
    ## used ancestor to ignore inconsistent <p> wrapping in their HTML
    html_elements(xpath = "//table//a/ancestor::td/preceding-sibling::td[2]") %>%
    html_text()
  
  date <- link_nodes %>% 
    ## find text 1 column before
    html_elements(xpath = "//table//a/ancestor::td/preceding-sibling::td[1]") %>%
    html_text()
  
  df <- tibble(delegation = delegation, 
               date = date,
               ## text of the link
               link_text = link_nodes %>% html_text(),
               ## link itself
               link = link_nodes %>% html_attr("href"))
  
  ## append to dataframe
  speaker_data <- rbind(speaker_data, df)
  
}

## clear everything except speaker data from global env
rm(list = ls()[! ls() %in% c("speaker_data")])

#### reading pdf files ####

## dataset to be populated
speech_data <- data.frame()

## read text of each pdf into tabular format
for (i in list(speaker_data$link)) {
  ## create and name temporary directory
  pdf_dir <- here(paste0("temp/"))
  dir.create(pdf_dir)
  
  ## download files to directory
  raw_list <- i %>%
    walk2(.,
          paste0(pdf_dir, 
                 "/" ,
                 "bbnj_",
                 ## shorten filenames
                 (str_remove(., "https://www.un.org/bbnj/sites/www.un.org.bbnj/files/")) 
          ),
          download.file, mode = "wb")
  
  ## find all downloaded files
  files <- list.files(here("temp"), pattern = "\\.pdf$")
  
  ## add path to file name
  files_dir <- paste("temp/", files, sep = "")
  
  ## read in text from each pdf file
  for (i in 1:length(files)) {
    curr <- data.frame(link = files_dir[i],
                       text = paste(pdf_text(files_dir[i]), collapse = " "))
    
    ## append to dataframe
    speech_data <- rbind(speech_data, curr)
  }
  
  ## remove created directory and files
  unlink(pdf_dir, recursive = TRUE)
  
}

#### join to create full speech dataset ####
speech_dat <- speaker_data %>%
  # shorten links to match
  mutate(link = str_replace(link, "https://www.un.org/bbnj/sites/www.un.org.bbnj/files/", "temp/bbnj_")) %>%
  left_join(speech_data, by = "link")

## save to rds
saveRDS(speech_dat, file = "data/02_tidy_data/speech_dat.rds")

## helpful sources
#### https://oceanhealthindex.org/news/scraping_webpages_and_pdfs/
#### https://stackoverflow.com/questions/63093926/retrieve-link-from-html-table-with-rvest
