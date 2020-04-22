library(tidyverse)
phd_field <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-02-19/phd_by_field.csv")
phd_field$broad_field <- as.factor(phd_field$broad_field)
phd_field$major_field <- as.factor(phd_field$major_field)
