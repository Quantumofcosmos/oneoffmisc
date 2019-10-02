library(tidyverse)
library(gganimate)
forex <- read_csv("forex1.csv",col_names = F)
forex$X1 <- str_sub(forex$X1,start = -4)

ppp <- read_csv("PPP.csv",col_names = T)
#ppp <- ppp[ppp$`Country Name`=='India',]
#ppp %>% pivot_longer(names_to = "year",values_drop_na = TRUE ,values_to = "ppower")
ppp <- gather(ppp[108,-(1:34)])
colnames(ppp) <- c("year","ppp")
colnames(forex) <- c("year","forex")
combined <- left_join(ppp,forex)
ggplot(combined)+geom_point(aes(year,ppp))+geom_point(aes(year,forex))
ggplot(combined)+geom_line(aes(year,ppp),group=1)+geom_line(aes(year,forex),group=1)+transition_states(
  year,
  transition_length = 2,
  state_length = 1
)
write_csv(combined,"/home/cosmos/projects/oneoffMisc/pppgif/combined.csv")
