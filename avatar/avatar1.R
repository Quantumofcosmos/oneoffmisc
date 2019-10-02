library(tidyverse)
library(rvest)
library(stringr)
library(rebus)
library(lubridate)
library(purrr)
library(ggthemes)


# Function to collect all dialogues 
# Takes no arguments; Returns DF with "speaker","dialogue","season","episode","len"(no of words in that dialogue)
init <- function() {
  # Function to collect all urls from list of episodes html
  # Takes no arguments; Returns vector(?) with urls of transcripts for each episode
  linklinker <- function() {
    reps <-
      read_html(url("https://avatar.fandom.com/wiki/Avatar_Wiki:Transcripts","rb")) %>%
      html_nodes("#mw-content-text > table ") %>%
      html_nodes("a") %>%
      html_attr("href") %>%
      str_c("https://avatar.fandom.com", .)
    ATLAurls <- reps[2:65]
    # removing non relevant episodes
    return(ATLAurls[-c(18, 20, 43)])
  }
  
  allurls <- linklinker()
  
  
  # Function to get season name from article tag
  # Takes HTML page as argument; Returns season name 
  getbooktag <- function(htmlbody) {
    tag <- htmlbody %>% html_node(".page-header__categories-links") %>%
      html_nodes("a:nth-of-type(3)") %>% 
      html_text() %>% 
      word(., 1, 3, sep =" ")
    return(tag)
  }
  
  # Function to get dialogue from single episode passed as HTML body
  # Takes HTML page, season name and episode number as arguments; Returns DF with speaker, dialogue, season name and episode number 
  getconv <- function(htmlbody, tag, w) {
    # First table has the speaker and dialogue
    frame <-htmlbody %>% html_node("table:nth-of-type(1)") %>% html_table()
    # Parse second table if first table is introduction
    if (grepl("Water. Earth. Fire. Air.", frame[1, 2])) {
      frame <-htmlbody %>% html_node("table:nth-of-type(2)") %>% html_table()
    }
    colnames(frame) <- c("speaker", "dialogue")
    frame$season <- tag
    frame$episode <- w
    return(frame)
  }
  
  # Function to get Dialogues from URL list
  # Takes URL vector as argument; Returns DF with speaker, dialogue, season name and episode number of all episodes  
  scrapper <- function(urls) {
    dialmaster <- data.frame(
      speaker = character(),
      dialogue = character(),
      season = character(),
      episode = integer(),
      stringsAsFactors = FALSE
    )
    w <- 1
    e <- 1
    f <- 1
    for (each in urls) {
      htmlx <- read_html(url(each, "rb"))
      tag <- getbooktag(htmlx)
      if (grepl("One", tag)) {
        print("okati")
        dialmaster <- getconv(htmlx, tag, as.double(paste(1, str_extract(paste(0, w, sep = ""), "[0-9]{2}$"), sep = "."))) %>% 
          bind_rows(dialmaster, .)
        w <- w + 1
      } else if (grepl("Two", tag)) {
        dialmaster <- getconv(htmlx, tag, as.double(paste(2, str_extract(paste(0, e, sep = ""), "[0-9]{2}$"), sep = "."))) %>% 
          bind_rows(dialmaster, .)
        e <- e + 1
        print("Rendu")
      } else {
        dialmaster <- getconv(htmlx, tag, as.double(paste(3, str_extract(paste(0, f, sep = ""), "[0-9]{2}$"), sep = "."))) %>% 
          bind_rows(dialmaster, .)
        f <- f + 1
        print("moodu")
      }
      # print(tag)
      # print(each)
    }
    return(dialmaster)
  }
  
  alldials <- scrapper(allurls)
  
  # Remove all the scene explainations which do not have speakers
  validdial <- filter(alldials,!speaker == "")
  
  # Remove all in dialogue scene explainations which are present as "[...]"
  subber <-   function(dial) {
    total <- str_remove_all(dial, "\\[[^\\]]+\\]")
    return(total)
  }
  
  validdial$dialogue <- sapply(validdial$dialogue, subber)
  
  validdial$len <-
    map_int(validdial$dialogue,  ~ str_count(., "\\S+"))
  return(validdial)
}

validdial <- init()


# Function to get aggregate of words spoken by each character in each episode 
# Takes character names and dialogue DF as arguments; Returns DF with speaker,episode,sequ,season,length 
dataer <- function(validdial) {
  plotd <- data.frame(
    speaker = character(),
    episode = integer(),
    sequ = integer(),
    season = integer(),
    length = integer(),
    stringsAsFactors = FALSE
  )
  charnames <- c("Aang", "Sokka", "Katara", "Zuko", "Toph", "Iroh", "Azula")
  for (name in charnames) {
    seqq <- 1
    tempchr <- filter(validdial, speaker == name)
    for (epi in unique(validdial$episode)) {
      tempepi <- filter(tempchr, episode == epi)
      plotd[nrow(plotd) + 1, ] = list(name, epi, seqq, as.integer(epi), sum(tempepi$len))
      seqq <- seqq + 1
    }
  }
  return(plotd)
}


testing <- dataer(validdial)

testing$season <- as.factor(testing$season)

filter(testing, length > 0) %>% ggplot(.,aes(x = sequ, y = length)) +
  geom_point(aes(color = season)) + geom_smooth() +  facet_wrap( ~ speaker)

filter(testing, length > 10) %>% ggplot(aes(x = sequ, y = length, color = season)) +
  geom_point() + geom_line(group = 1) +
  facet_wrap( ~ speaker)

plotp <- data.frame(
  speaker = character(),
  episode = integer(),
  season = integer(),
  percentshare = integer(),
  stringsAsFactors = FALSE
)

for (speakr in unique(testing$speaker)) {
  for (each in unique(validdial$episode)) {
    wordsperepi <- validdial %>% filter(episode == each) %>% select(len) %>% sum()
    season <- validdial %>% filter(episode == each) %>% select(season) %>% head(1) %>% unlist()
    wordsperepichar <- testing %>% filter(episode == each) %>% 
      filter(speaker == speakr) %>% select(length) %>% unlist()
    plotp[nrow(plotp) + 1, ] = list(speakr, each,season,round((wordsperepichar/wordsperepi)*100) )
  }
}

rm(each,season,speakr,wordsperepi,wordsperepichar)

plotp$episode <- as.factor(plotp$episode)
plotp$season <- as.factor(plotp$season)
filter(plotp, percentshare > 0) %>% ggplot(aes(x = episode, y = percentshare)) +
  geom_point(aes(color=season)) + geom_line(group = 1) +
  facet_wrap( ~ speaker)

plotp$episode <- as.integer(plotp$episode)
filter(plotp, percentshare > 0) %>% ggplot(.,aes(x = episode, y = percentshare)) +
  geom_point(aes(color=season)) + geom_smooth(se = FALSE) +  facet_wrap( ~ speaker) + 
  scale_color_fivethirtyeight() + theme_fivethirtyeight()
