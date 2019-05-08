theme_white <- function() {
  theme_update(
    plot.title = element_text(size=22),
    axis.text.y =element_text(size=10),
    axis.title = element_text(size=17),
    legend.title = element_text(size = 16),
    legend.text = element_text(size = 14),
    axis.text.x = element_text(size=18, angle = 0),
    strip.text.y = element_text(size = 12, angle = 90),
    strip.text.x = element_text(size = 18, angle = 0)
  )
}

theme_set(theme_bw())
theme_white()

execution.times <- read.csv("results/library/scaling_vs_execution_time2/app_conf.txt")
execution.times <- filter(execution.times, execution_time >= 0)
execution.times$application <- factor(execution.times$application, labels = c(c("1", "2", 
                                                                                "3", "4")))
min.10 <- 554
min.20 <- 1104
min.30 <- 1662
min.40 <- 2216
min.50 <- 2770
min.60 <- 3324

deadlines <- data.frame(
  application = factor(c("1", "2", 
                         "3", "4")),
  execution_time = c(min.30, min.40, min.50, min.60),
  lower = c(min.30, min.40, min.50, min.60)
)

ggplot() + 
  geom_errorbar(data = deadlines, aes(application, ymin = lower, ymax = execution_time, colour = "red")) + 
  geom_boxplot(data = execution.times, aes(x = application, y = execution_time)) +
  geom_point(data = execution.times, aes(x = application, y = execution_time)) +
  xlab("Aplicação") +
  ylab("Tempo de execução") +
  theme(legend.position="none")

ggsave("timevsscaling.png")

execution.times.30 <- execution.times %>% filter(application == "cpu_bound_scripted_30min")
execution.times.40 <- execution.times %>% filter(application == "cpu_bound_scripted_40min")
execution.times.50 <- execution.times %>% filter(application == "cpu_bound_scripted_50min")
execution.times.60 <- execution.times %>% filter(application == "cpu_bound_scripted_60min")

nrow(filter(execution.times.30, execution_time <= min.30))/nrow(execution.times.30)
nrow(filter(execution.times.40, execution_time <= min.40))/nrow(execution.times.40)
nrow(filter(execution.times.50, execution_time <= min.50))/nrow(execution.times.50)
nrow(filter(execution.times.60, execution_time <= min.60))/nrow(execution.times.60)
