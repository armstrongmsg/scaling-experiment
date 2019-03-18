library(ggplot2)
library(dplyr)

data <- read.csv("task.csv")

summarized.data <- data %>% group_by(change, interval = ceiling(seq_along(task)/(10))) %>% 
  summarize(var_mean = mean(perf))

ggplot(summarized.data, aes(interval, var_mean)) + 
  geom_line() + 
  facet_wrap(~change, scales = "free") + 
  xlab("") +
  ylab("Performance (tasks/sec)")

ggsave("pid_tuning.png")