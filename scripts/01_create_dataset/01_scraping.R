## bbnj web scraping script

## load packages
library(tidyverse)
library(here)
library(rvest)
library(pdftools)

#### scrape tables to get links to each speech pdf ####

# read in webpages
page1 <- read_html("https://www.un.org/bbnj/statements-first-session")
page2 <- read_html("https://www.un.org/bbnj/statements-second-session")
page3 <- read_html("https://www.un.org/bbnj/statements-third-session")
page4 <- read_html("https://www.un.org/bbnj/statements")
page5 <- read_html("https://www.un.org/bbnj/statements-fifth-session")

pages <- list(page1, page2, page3, page4, page5)

# empty dataframe to populate with link information
speaker_data <- data.frame()

for (page in pages) {
  
  # find all nodes inside a table containing a link
  link_nodes <- page %>% 
    html_nodes(xpath = "//table//a")  
  
  link_text  <- link_nodes %>% html_text()
  
  delegation <- link_nodes %>% 
    ## find the text in the cell 2 columns before each link (speaker)
    ## used ancestor to ignore inconsistent <p> wrapping in their HTML
    html_elements(xpath = "//table//a/ancestor::td/preceding-sibling::td[2]") %>%
    html_text()
  
  date <- link_nodes %>% 
    ## find text in the cell 1 column before (date of speech)
    html_elements(xpath = "//table//a/ancestor::td/preceding-sibling::td[1]") %>%
    html_text()
  
  df <- tibble(delegation = delegation, 
               date = date,
               link_text = link_nodes %>% html_text(),
               link = link_nodes %>% html_attr("href"))
  
  # append link information as a row to speaker_data
  speaker_data <- rbind(speaker_data, df)
  
}

# clear everything except speaker data from global environment
rm(list = ls()[! ls() %in% c("speaker_data")])

#### reading text of pdf files ####

speech_data <- data.frame()

# reading text of each pdf into tabular format
for (i in list(speaker_data$link)) {
  
  # create and name temporary directory
  pdf_data <- here(paste0("temp/"))
  dir.create(pdf_data)
  
  # download files to directory
  raw_list <- i %>%
    walk2(.,
          paste0(pdf_data, 
                 "/" ,
                 "bbnj_",
                 ## shorten filenames
                 (str_remove(., "https://www.un.org/bbnj/sites/www.un.org.bbnj/files/")) 
          ),
          download.file, mode = "wb")
  
  # find all downloaded files
  files <- list.files(here("temp"), pattern = "\\.pdf$")
  files_dir <- paste("temp/", files, sep = "")
  
  # read in text from each pdf file
  for (i in 1:length(files)) {
    curr <- data.frame(link = files_dir[i],
                       text = paste(pdf_text(files_dir[i]), collapse = " "))
    
    # append as a row to speech_data
    speech_data <- rbind(speech_data, curr)
  }
  
  # remove created directory and pdfs
  unlink(pdf_data, recursive = TRUE)
  
}

#### join to create full speech dataset ####

speech_dat <- speaker_data %>%
  mutate(link = str_replace(link, "https://www.un.org/bbnj/sites/www.un.org.bbnj/files/", "temp/bbnj_")) %>%
  left_join(speech_data, by = "link")

saveRDS(speech_dat, file = "data/02_tidy_data/speech_dat.rds")
