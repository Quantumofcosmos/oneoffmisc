
library(jasmines)

p1 <- use_seed(1) %>%
  entity_circle(grain = 1000) %>% 
  unfold_slice(scale = 1) %>%
  style_ribbon(background = "wheat")

use_seed(1) %>%
  entity_circle(grain = 1000) %>% 
  unfold_slice(scale = 2) %>%
  style_walk(background = "wheat")

p3 <- use_seed(1) %>%
  entity_circle(grain = 1000) %>% 
  unfold_warp(scale = 0.4) %>%
  style_ribbon(background = "wheat")

p4 <- use_seed(1) %>%
  entity_circle(grain = 1000) %>% 
  unfold_warp(scale = 0.8) %>%
  style_ribbon(background = "wheat")

plot_grid(p1,p2)
plot_grid(p3,p4)


entity_circle(grain = 10) %>% 
  unfold_warp(scale = 2,iterations = 4) %>% view()
  style_ribbon(background = "wheat",type = "curve")


library(tidyverse)
ggplot(pp[["data"]])+geom_line(aes())