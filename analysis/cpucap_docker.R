library(ggplot2)
library(dplyr)

theme_white <- function() {
  theme_update(
    plot.title = element_text(size=22),
    axis.text.y =element_text(size=10),
    axis.title = element_text(size=17),
    legend.title = element_text(size = 16),
    legend.text = element_text(size = 14),
    axis.text.x = element_text(size=15, angle = 10, hjust = 1),
    strip.text.y = element_text(size = 12, angle = 90),
    strip.text.x = element_text(size = 18, angle = 0)
  )
}

theme_set(theme_bw())
theme_white()

results <- read.csv("results_cpucap_docker.csv")

mean.100 <- mean(filter(results, cap == 100)$time)

results$reference <- mean.100*100/results$cap

results %>% ggplot(aes(cap, time, group = cap)) + 
  geom_boxplot() +
  geom_line(data = results, aes(cap, reference, colour = "red", group = 1)) + 
  xlab("CPU cap (%)") + 
  ylab("Time (in seconds)") + 
  theme(legend.position="none")

ggsave("captime_container.png")