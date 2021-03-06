library(ggplot2)
library(reshape2)
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

min.max <- function(erro) {
  base <- 50
  max <- 100
  r <- max
  if (erro > 0) {
    r <- base
  }
  return(r)
}

theme_set(theme_bw())
theme_white()

controller_labels <- c(`erro` = "Erro", `prop` = "Proporcional", 
                       `deriv` = "Proporcional-Derivativo", 
                       `pid` = "PID", `min.max` = "Min-Max")

factor_p <- 0.2
factor_d <- 2
factor_i <- 0.05

erro <- c(0, 0, 0, 0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.11, 
          0.1, 0.09, 0.08, 0.07, 0.06, 0.05, 0.04, 0.03, 0.02, 0.01, 0, 
          -0.01, -0.02, -0.03, -0.04, -0.05, -0.06, -0.07, -0.06, -0.05, -0.04, -0.03, 
          -0.02, -0.01, 0)
x <-seq(1, length(erro))

df <- data.frame(time=x,erro=erro)
diff_err <- sapply(2:length(x), function(x) df$erro[x] - df$erro[x-1])
diff_err[length(x)] <- 0
df <- data.frame(time=x,erro=erro,diff_err=diff_err)
df$prop <- -factor_p*df$erro
df$deriv <- -(factor_p*df$erro + factor_d*df$diff_err)
df$diff_err <- -df$diff_err
df$cum_err <- cumsum(erro)
df$pid <- -(factor_p*df$erro + factor_d*df$diff_err + factor_i*df$cum_err)
min.max.data <- sapply(1:length(x), function(x) min.max(df$erro[x]))
df$min.max <- min.max.data

demo.data <-melt(df, id = c("time"))

#
# Case 1: Proportional
#

ggplot(filter(demo.data, demo.data$variable %in% c("erro", "prop")), aes(x = time, y = value, colour = variable)) + 
    geom_line() +
    xlab("Tempo") +
    ylab("") +
    facet_grid(. ~ variable, labeller = labeller(variable = controller_labels)) +
    theme(legend.position="none")

ggsave("proportional_demo.png")

#
# Case 2: Proportional-Derivative
#

ggplot(filter(demo.data, demo.data$variable %in% c("erro", "deriv")), aes(x = time, y = value, colour = variable)) + 
  geom_line() +
  xlab("Tempo") +
  ylab("") +
  facet_grid(. ~ variable, labeller = labeller(variable = controller_labels)) +
  theme(legend.position="none")

ggsave("proportional_deriv_demo.png")

#
# Case 3: PID
#

ggplot(filter(demo.data, demo.data$variable %in% c("erro", "pid")), aes(x = time, y = value, colour = variable)) + 
  geom_line() +
  xlab("Tempo") +
  ylab("") +
  facet_grid(. ~ variable, labeller = labeller(variable = controller_labels)) +
  theme(legend.position="none")

ggsave("pid_demo.png")

#
# Case 4: Min-Max
#

ggplot(filter(demo.data, demo.data$variable %in% c("erro", "min.max")), aes(x = time, y = value, colour = variable)) + 
  geom_line() +
  xlab("Tempo") +
  ylab("") +
  facet_wrap(~variable, labeller = labeller(variable = controller_labels), scales = "free_y") +
  theme(legend.position="none")

ggsave("minmax_demo.png")

# 
# All
#

ggplot(filter(demo.data, demo.data$variable %in% c("erro", "prop", "deriv", "pid")), aes(x = time, y = value, colour = variable)) + 
  geom_line() +
  xlab("Tempo") +
  ylab("") +
  facet_grid(. ~ variable, labeller = labeller(variable = controller_labels)) +
  theme(legend.position="none")

ggsave("all_demo.png")
