library(rvest)
library(tidyverse)
library(lubridate)

title <- read_html("udemy.html") %>% html_nodes(.,".curriculum-item--curriculum-item--iJwX5") %>% 
  html_nodes("a") %>% html_nodes(".curriculum-item--title--3etrQ") %>% html_text() %>% 
  .[-c(3,4,5,8,10,15,18,22,23,36,43,51,57,58,87,88,103,108,140,141,148,163,164,165,177,196,209,220,221,233,258,269,270,286,298)]

durmin <- read_html("udemy.html") %>% html_nodes(.,".curriculum-item--curriculum-item--iJwX5") %>% 
  html_nodes("a") %>% html_nodes(".curriculum-item--duration--1OEOp") %>% html_text() %>% 
  ms(.) %>% minute()

dursec <- read_html("udemy.html") %>% html_nodes(.,".curriculum-item--curriculum-item--iJwX5") %>% 
  html_nodes("a") %>% html_nodes(".curriculum-item--duration--1OEOp") %>% html_text() %>% 
  ms(.) %>% second()

statuss <- read_html("udemy.html") %>% html_nodes(.,".curriculum-item--curriculum-item--iJwX5") %>% 
  html_nodes("a") %>% html_nodes(".curriculum-item--progress--3eKMJ") %>% 
  as.character() %>% str_detect(.,"--is-completed") %>% 
  .[-c(3,4,5,8,10,15,18,22,23,36,43,51,57,58,87,88,103,108,140,141,148,163,164,165,177,196,209,220,221,233,258,269,270,286,298)]

course <- data.frame(title,durmin,dursec,statuss)

howmuch <- function(a){
((course %>% filter(statuss==a) %>% select(durmin) %>% mutate(durmin=durmin*60) %>% sum()) +(course %>% filter(statuss==a) %>% select(dursec) %>% sum())) %>%
  seconds_to_period()
}
howmuch(TRUE)
howmuch(FALSE)
