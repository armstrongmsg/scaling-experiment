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

speedup <- read.csv("speedup.csv")
speedup_times <- read.csv("speedup_time.csv")

speedup %>% ggplot(aes(time, completed_tasks, group = exec_id)) +
  geom_point(size = 0.1) +
  geom_vline(xintercept = speedup_times$speedup_time, color = "red")

all_tasks_before_speedup <- c()
perf_before <- c()
perf_after <- c()

for (execution in speedup_times$exec_id) { 
  speedup_time <- speedup_times[speedup_times$exec_id==execution,]$speedup_time; 
  before_tasks <- filter(speedup, exec_id == execution & time < speedup_time);
  after_tasks <- filter(speedup, exec_id == execution & time >= speedup_time);
  tasks_before_speedup <- last(before_tasks$completed_tasks);
  execution_time <- last(after_tasks$time);
  all_tasks_before_speedup <- c(all_tasks_before_speedup, tasks_before_speedup);
  perf_before <- c(perf_before, last(before_tasks$completed_tasks)/speedup_time);
  perf_after <- c(perf_after, (last(after_tasks$completed_tasks) - last(before_tasks$completed_tasks))/(execution_time - speedup_time));
}

mean_perf_before <- mean(perf_before)
mean_perf_after <- mean(perf_after)
mean_speedup_time <- mean(speedup_times$speedup_time)
mean_tasks_before_speedup <- mean(all_tasks_before_speedup)

data_after_speedup <- filter(speedup, time > mean_speedup_time)

#
# All execution
#
speedup %>% ggplot(aes(time, completed_tasks, group = exec_id)) + 
  # base performance line
  geom_line(data = speedup, aes(time, mean_perf_before*time), color = "blue") + 
  # target performance line
  geom_line(data = data_after_speedup, aes(time, mean_tasks_before_speedup + 
                                                 mean_perf_after*(time - mean_speedup_time)), color = "orange") + 
  geom_point(size = 0.1) +
  geom_vline(xintercept = speedup_times$speedup_time, color = "red")

#
# After speedup
#
data_after_speedup %>% ggplot(aes(time, completed_tasks, group = exec_id)) + 
  # base performance line
  geom_line(data = data_after_speedup, aes(time, mean_perf_before*time), color = "blue") + 
  # target performance line
  geom_line(data = data_after_speedup, aes(time, mean_tasks_before_speedup + 
                                           mean_perf_after*(time - mean_speedup_time)), 
                                           color = "orange") + 
  geom_line(size = 0.1) +
  geom_vline(xintercept = speedup_times$speedup_time, color = "red")

#
# Using base performance as reference
#
data_after_speedup %>% ggplot(aes(time, completed_tasks - mean_perf_before*time, group = exec_id)) + 
  # base performance line
  geom_line(data = data_after_speedup, aes(time, 0), color = "blue") + 
  # target performance line
  geom_line(data = data_after_speedup, aes(time, mean_tasks_before_speedup + 
                                             mean_perf_after*(time - mean_speedup_time) - 
                                             mean_perf_before*time), 
            color = "orange") + 
  geom_line(size = 0.1) +
  geom_vline(xintercept = speedup_times$speedup_time, color = "red")
