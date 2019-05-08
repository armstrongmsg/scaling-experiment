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

# -----------------------------------------------------------------
#
# Aggregate
#
# -----------------------------------------------------------------

# Plot cap behavior vs timestamp

data$scaling_conf <- factor(data$scaling_conf, labels = c("progress-error-aggressive", "progress-error-conservative", 
                                                          "progress-error-regular", "progress-tendency", 
                                                          "proporcional-aggressive", "proporcional-conservative", "proporcional-regular"))
ggplot(data, aes(timestamp, cap, group=interaction(application_id))) + geom_line() + facet_grid(. ~ scaling_conf) + theme_bw(base_size = 15)

# -------------------------------------

# Plot time spent in each cap
instance_id_ <- "81314c1a-50c6-4888-9756-5c97732212b0"
data_agg <- filter(data_agg, timestamp >= 0)
diffs <- c(diff(data_agg$timestamp),0)
data_agg$diffs <- diffs
data_agg <- filter(data_agg, diffs >= 0)
result <- data_agg %>% filter(instance_id == instance_id_) %>% group_by(application_id, total_time, cap) %>% summarise(total_time_in_cap=sum(diffs))
result$ratio_time_in_cap <- result$total_time_in_cap/result$total_time
result_final <- result %>% group_by(cap) %>% summarise(mean=mean(ratio_time_in_cap)) 
result$cap <- as.factor(result$cap)
  
# Per application
ggplot(result, aes(cap, ratio_time_in_cap)) + geom_bar(stat = "identity") + facet_grid(. ~ application_id) + theme_bw(base_size = 15)

# Summarized (mean)       
ggplot(result_final, aes(cap, mean)) + geom_bar(stat = "identity") + theme_bw(base_size = 15)
