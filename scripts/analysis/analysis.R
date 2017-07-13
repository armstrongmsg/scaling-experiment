library(ggplot2)

line_data <- data.frame(variable = c("app_time"), Y = c(240))

melt(results, id = c("app_id", "conf", "start_cap")) %>% ggplot(aes(conf, value)) + 
  geom_boxplot() + facet_grid(variable ~ ., scales = "free") +
  geom_hline(data = line_data, colour = "blue", aes(yintercept = Y)) +
  scale_x_discrete()

ggsave("results.png", width = 20, height = 10)

# -----------------------------------------------------------------
#
# cap-time
#
# -----------------------------------------------------------------

times <- read.csv("application_time.log", sep = "|")
caps <- read.csv("app_conf.txt", sep = "|")

times$cap <- as.factor(caps$cap)

ggplot(times, aes(cap, execution_time)) + geom_boxplot()

ggsave("results_cap.png")

# -----------------------------------------------------------------
#
# cap-time version 2
#
# -----------------------------------------------------------------

cap_times <- read.csv("results.csv", sep = "|")

cap_times$cap <- as.factor(cap_times$cap)

ggplot(cap_times, aes(cap, time)) + geom_boxplot()

ggsave("results_cap.png")
