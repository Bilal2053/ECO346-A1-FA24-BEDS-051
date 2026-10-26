# 01_default.R -- Q4 default figure: R's defaults, untouched.
source("scripts/00_setup.R")

p <- ggplot(earners, aes(age, earn_annual)) + geom_point()

ggsave("figures/default.svg", p, width = 7, height = 5)
