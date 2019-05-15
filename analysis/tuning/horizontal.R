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

caps <- read.csv("cap.log")
times <- read.csv("time.log")

deadline <- 749

ggplot(times, aes(controller, execution_time)) + 
  geom_boxplot() +
  geom_hline(yintercept = deadline, color = "red") +
  xlab("Controller") +
  ylab("Execution time (s)")

ggsave("times.png")

ggplot(caps, aes(time, replicas, group = exec_id)) + 
  geom_line() + 
  facet_grid(. ~ controller) +
  xlab("Time (s)") +
  ylab("Replicas")

ggsave("replicas.png")

ggplot(caps, aes(time, calculated_replicas, group = exec_id)) + 
  geom_line() + 
  facet_grid(. ~ controller) +
  xlab("Time (s)") +
  ylab("Replicas")

ggsave("replicas_calculated.png")
