library(tidyverse)
library(gganimate)
library(ggthemes)

# forex <- read_csv("forex1.csv",col_names = F)
# forex$X1 <- str_sub(forex$X1,start = -4)
# 
# ppp <- read_csv("PPP.csv",col_names = T)
# 
# ppp <- gather(ppp[108,-(1:34)])
# 
# colnames(ppp) <- c("year","ppp")
# colnames(forex) <- c("year","forex")
# combined <- left_join(ppp,forex)

combined <- read_csv("combined.csv")
combined_long <- pivot_longer(combined,cols = c("PPP","forex"),names_to = "type",values_to = "rate")



ggplot(combined_long, aes(year, rate, group = type, color=type)) + 
  geom_line() + xlim(1989,2020) + ylim(0,75) + 
  scale_x_continuous(breaks = seq(1990, 2020, by = 5)) +
  scale_y_continuous(breaks = seq(0, 70, by = 10)) +
  geom_vline(aes(xintercept = year), linetype = 11, colour = 'grey') + 
  geom_point(size = 2) + 
  geom_text(aes(x = year +1 , label = format(round(rate, 2), nsmall = 2)), hjust = 0) + 
  geom_text(aes(x = year +1 ,y=73, label = paste(year,".",sep = "")), hjust = 0) + 
  transition_reveal(year) + 
  coord_polar(clip = 'off') +
  # coord_cartesian(clip = 'off') + 
  labs(title = 'Exchange rate - USD vs INR', subtitle = "Story of how the traded value balooned but the PPP index remained steady", y = 'Exchange rate') + 
  theme_solarized() + scale_colour_solarized() + 
  theme(plot.margin = margin(5.5, 60, 5.5, 5.5),legend.position = "bottom")
ggsave("forexVSppp.png")

anim_save("forexVSppp.gif")
