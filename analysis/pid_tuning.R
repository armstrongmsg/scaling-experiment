library(ggplot2)
library(dplyr)
library(zoo)

data <- read.csv("task.csv")

summarized.data <- data %>% group_by(change, interval = ceiling(seq_along(task)/(10))) %>% 
  summarize(var_mean = mean(perf))

summarized.data2 <- data %>% mutate(aa=rollapplyr(data$perf,200,mean,partial=TRUE))

ggplot(summarized.data, aes(interval, var_mean)) + 
  geom_line() + 
  facet_wrap(~change, scales = "free") + 
  xlab("") +
  ylab("Performance (tasks/sec)")

ggplot(summarized.data2, aes(time, aa)) + 
  geom_line() + 
  facet_wrap(~change, scales = "free") + 
  xlab("") +
  ylab("Performance (tasks/sec)")

# -------------------------------------------------------------

tasks <- read.csv("task.csv")
change <- read.csv("change.csv")

tasks$time <- tasks$time - tasks$time[1]
tasks$time <- tasks$time/10^9
change$time <- change$time/10^9

diff_frame <- data.frame(diff(as.matrix(select(tasks, time, tasks))))
diff_frame$perf <- diff_frame$tasks/diff_frame$time
tasks$perf <- c(0,diff_frame$perf)

tasks <- tasks %>% mutate(run_mean=rollapplyr(perf,20,mean,partial=TRUE))

ggplot(filter(tasks, run_mean > 0), aes(time, run_mean)) + 
  geom_line(colour = "red", size = 1) + 
  geom_point(data = tasks, aes(time, perf), size = 0.5) +
  geom_vline(data = change, aes(xintercept = time), colour = "blue") +
  facet_wrap(~change, scale = "free") +
  xlab("Time") +
  ylab("Performance (tasks/sec)")

ggsave("pid_tuning.png")
