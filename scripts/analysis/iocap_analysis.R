library(dplyr)
library(ggplot2)

mean.100 <- mean(filter(app_conf, cap == "100")$execution_time)
reference <- data.frame(cap = 7:100, execution_time = rapply(as.list(7:100), function(x) mean.100*100/x))
ggplot() + 
    geom_boxplot(data = app_conf, aes(x = cap, y = execution_time, group = cap)) + 
    geom_line(data = reference, aes(x = cap, y = execution_time, colour = "red")) + 
    theme(legend.position="none") + 
    xlab("I/O cap") + 
    ylab("Tempo de execução (em segundos)")

ggsave("iocapvstime.png")
