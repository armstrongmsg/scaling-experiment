library(ggplot2)
library(dplyr)
library(reshape2)

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

results.30rep.5step <- read.csv("results-30rep-5step.csv")
results.30rep.5step <- filter(results.30rep.5step, CAP %in% seq(10,100,10))
mean.100 <- mean(filter(results.30rep.5step, CAP == 100)$time)

results.30rep.5step$reference <- mean.100*100/results.30rep.5step$CAP
results.30rep.5step$actual_loss <- (results.30rep.5step$time - mean.100)/mean.100
results.30rep.5step$expected_loss <- (results.30rep.5step$reference - mean.100)/mean.100

# Actual time and expected time
ggplot() + 
  geom_boxplot(data = results.30rep.5step, aes(as.factor(CAP), time)) + 
  geom_line(data = results.30rep.5step, aes(as.factor(CAP), reference, colour = "red", group = 1)) + 
  xlab("CPU cap (%)") + 
  ylab("Execution time (s)") + 
  theme(legend.position="none")

ggsave("cpucapvstime.png")
