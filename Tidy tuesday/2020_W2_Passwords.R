library(tidyverse)
library(chorddiag)
library(RColorBrewer)
library(reshape2)
passwords <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-01-14/passwords.csv')

passwords %>% 
  mutate(first=substr(passwords$password,1,1)) %>% 
  mutate(second=substr(passwords$password,2,2)) %>% 
  select(first,second) %>% na.omit() %>% 
  dcast(first~second) %>% # counting how many times each pair occors
  mutate(f=0,g=0,j=0,q=0,v=0) %>% # adding columns of missing alphabets 
  select(order(colnames(.))) %>% select(-first) %>% 
  rbind(rep(0,37),.)  %>% as.matrix() %>% # adding row as no password started with 0
  chorddiag(groupColors = colorRampPalette(brewer.pal(12, "Set3"))(36)) 

setwd("~/projects/comicgen")


library(tidyverse)
library(chorddiag)
library(RColorBrewer)
library(reshape2)
passwords <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-01-14/passwords.csv')

powpowpow <- passwords %>% 
  filter(category %in% c('food','simple-alphanumeric','nerdy-pop','password-related','animal','sport')) %>% 
  mutate(multiplier = case_when(time_unit == 'years' ~ 31556926,
                                time_unit == 'months' ~ 2592000,
                                time_unit == 'weeks' ~ 604800,
                                time_unit == 'days' ~ 86400,
                                time_unit == 'hours' ~ 3600,
                                time_unit == 'minutes' ~ 60,
                                time_unit == 'seconds' ~ 1)) %>%
  mutate(aslitime=multiplier*value) %>% select(-offline_crack_sec,-rank_alt) 
ggplot(aes(x=rank,y=font_size,color=category))+geom_point()
# +scale_y_log10()
