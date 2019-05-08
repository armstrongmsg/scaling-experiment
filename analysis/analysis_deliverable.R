theme_white1 <- function() {
  theme_update(
    plot.title = element_text(size=22),
    axis.text.y =element_text(size=19),
    axis.title = element_text(size=20),
    legend.title = element_text(size = 16),
    legend.text = element_text(size = 14),
    axis.text.x = element_text(size=22, angle = 20, hjust = 1),
    strip.text.y = element_text(size = 18, angle = 90),
    strip.text.x = element_text(size = 18, angle = 0)
  )
}

theme_white2 <- function() {
  theme_update(
    plot.title = element_text(size=22),
    axis.text.y =element_text(size=19),
    axis.title = element_text(size=20),
    legend.title = element_text(size = 16),
    legend.text = element_text(size = 14),
    axis.text.x = element_text(size=22, angle = 0, hjust = 1),
    strip.text.y = element_text(size = 18, angle = 90),
    strip.text.x = element_text(size = 18, angle = 0)
  )
}

theme_set(theme_bw())
theme_white1()

results <- melt(results_deliverable, id=c("app_id", "starting_cap", "scaling_conf"))
results <- filter(results, scaling_conf != "progress-tendency")
levels(results$variable) <- c("CPU Usage", "Application time")

# Add plugins column
results <- transform(results, plugin = ifelse(grepl("progress-error", scaling_conf), "Progress Error", 
                                                               ifelse(grepl("proportional-derivative", scaling_conf), "Proportional Derivative", 
                                                                      "Proportional")))
# Add configuration column
results <- transform(results, configuration = ifelse(grepl("conservative", scaling_conf), "Conservative", 
                                                                      ifelse(grepl("regular", scaling_conf), "Regular", 
                                                                             "Aggressive")))
ggplot(results, aes(configuration, value)) + 
  geom_boxplot() + 
  facet_grid(variable ~ plugin, scales = "free") + 
  xlab("Controller") + 
  ylab("") + 
  theme_white()


theme_set(theme_bw())
theme_white2()

aggregated.results <- aggregated
aggregated.results <- filter(aggregated.results, instance_id == "48006d48-b5ff-4642-b9e3-5cfe51608f02")
aggregated.results <- filter(aggregated.results, application_id %in% c("osspark0", "osspark1", "osspark2"))
aggregated.results <- filter(aggregated.results, adjusted_timestamp >= 0)

aggregated.results$application_conf <- as.factor(aggregated.results$application_conf)
levels(aggregated.results$application_conf) <- c("Progress Error - Aggressive", "Progress Error - Regular", "Proportional Derivative - Regular")

ggplot(aggregated.results, aes(adjusted_timestamp, host_cpu_usage, group=interaction(application_id, instance_id))) + 
  geom_line() + 
  facet_grid(. ~ application_conf) +
  xlab("Time") +
  ylab("Compute node CPU Usage") +
  theme_white()

ggplot(aggregated.results, aes(adjusted_timestamp, cap, group=interaction(application_id, instance_id))) + 
  geom_line() + 
  facet_grid(. ~ application_conf) +
  xlab("Time") +
  ylab("CPU cap") +
  theme_white()

# -------------------------------------------------------------------------------------------------------------
# I/O validation
# -------------------------------------------------------------------------------------------------------------

theme_white3 <- function() {
  theme_update(
    plot.title = element_text(size=22),
    axis.text.y =element_text(size=19),
    axis.title = element_text(size=20),
    legend.title = element_text(size = 16),
    legend.text = element_text(size = 14),
    axis.text.x = element_text(size=22, angle = 0, hjust = 1),
    strip.text.y = element_text(size = 18, angle = 90),
    strip.text.x = element_text(size = 18, angle = 0)
  )
}

theme_set(theme_bw())
theme_white3()

io.validation.review$config_io <- as.factor(io.validation.review$config_io)
levels(io.validation.review$config_io) <- c("KVM I/O plugin", "KVM CPU cap plugin")
ggplot(io.validation.review, aes(cap, execution_time)) + 
  geom_boxplot() + 
  facet_grid(. ~ config_io) + 
  theme_set(theme_bw()) +
  xlab("Cap") + 
  ylab("Execution time (in seconds)")

io.validation.review %>% 
  select(execution_time, cap, config_io) %>% 
  group_by(config_io, cap) %>% 
  summarise(mean(execution_time), median(execution_time))


