library(ggplot2)
library(dplyr)
library(scales)

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

save_plot <- function(filename) {
  ggsave(paste(PLOT_DIRECTORY, filename, sep = "/"), width = 6, height = 6)
}

theme_set(theme_bw())
theme_white()

resources_labels <- c(cpu_usage = "CPU (%)", read_bytes = "Leitura (MB)",
                      written_bytes = "Escrita (MB)", host_cpu_usage = "host_cpu_usage", 
                      progress = "Progresso")

application_labels <- c(cpu_bound_scripted_profile = "Aplicação limitada por CPU", 
                        cpu_bound_scripted = "Aplicação limitada por CPU",
                        emaas = "EMaaS", kmeans = "K-Means", wordcount_profile = "Wordcount", 
                        wordcount = "Wordcount", pure_io = "I/O",
                        pure_io_profile = "Aplicação limitada por IO",
                        `pure-io-dist-adjusted` = "I/O ajustada")

scaling_labels <- c(pid.all = "PID", pid.pd_only = "Proporcional-\nDerivativo", 
                    pid.p_only = "Proporcional", `progress-error.regular` = "Min-Max",
                    pid.super_d = "PD ajustado")

scaling_labels_eng <- c(pid.all = "PID", pid.pd_only = "Proportional-\nDerivative", 
                    pid.p_only = "Proportional", `progress-error.regular` = "Min-Max",
                    pid.super_d = "")

PLOT_DIRECTORY <- "emaas"
deadlines <- c(cpu_bound_scripted = 2060, pure_io = 2733, emaas = 2347)

aggregated_data <- read.csv("aggregated.csv")
resources_data <- read.csv("resources.csv")

#
#
### CPU bound 
#
#

cpu_bound <- filter(aggregated_data, application == "cpu_bound_scripted")

#
# Written bytes
#

ggplot(cpu_bound, aes(timestamp, written_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Dados escritos (em MB)") +
  facet_grid(application ~ application_conf, scales = "free", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("cpu_bound_written.png")

#
# Read bytes
#

ggplot(cpu_bound, aes(timestamp, read_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Dados lidos (em MB)") +
  facet_grid(application ~ application_conf, scales = "free", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("cpu_bound_read.png")

#
# CPU
#

ggplot(cpu_bound, aes(timestamp, cpu_usage, group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Uso de CPU") +
  facet_grid(application ~ application_conf, scales = "free", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("cpu_bound_cpu.png")

#
# Cap
#

ggplot(cpu_bound, aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab("Tempo") +
  ylab("Cap") +
  facet_grid(application ~ application_conf, scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("cpu_bound_cap.png")

#
# Time
#

cpu_bound.deadline <- deadlines["cpu_bound_scripted"][[1]]
ggplot(cpu_bound, aes(application_conf, application_time),  
                labeller = labeller(x = scaling_labels)) + 
  geom_boxplot() + 
  geom_point() +
  xlab("Controlador") +
  ylab("Tempo de execução") +
  geom_hline(aes(yintercept=cpu_bound.deadline), color = "red", linetype="dashed") +
  geom_text(aes(1, cpu_bound.deadline, label = paste("Prazo =", cpu_bound.deadline), vjust = -1)) +
  scale_x_discrete(labels=scaling_labels)
save_plot("cpu_bound_time.png")


#
#
### IO bound 
#
#

io_bound <- filter(aggregated_data, application == "pure_io" & application_conf != "pid.super_d")

#
# Written bytes
#

io_bound$written_bytes <- as.numeric(io_bound$written_bytes)
ggplot(io_bound, aes(timestamp, written_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Dados escritos (em MB)") +
  facet_grid(application ~ application_conf, scales = "free", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound_written.png")

#
# Read bytes
#

ggplot(io_bound, aes(timestamp, read_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Dados lidos (em MB)") +
  facet_grid(application ~ application_conf, scales = "free", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound_read.png")

#
# CPU
#

ggplot(io_bound, aes(timestamp, cpu_usage, group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Uso de CPU") +
  facet_grid(application ~ application_conf, scales = "free", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound_cpu.png")

#
# Cap
#

ggplot(io_bound, aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab("Tempo") +
  ylab("Cap") +
  facet_grid(application ~ application_conf, scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound_cap.png")

#
# Time
#

io_bound.deadline <- deadlines["pure_io"][[1]]
ggplot(io_bound, aes(application_conf, application_time),  
       labeller = labeller(x = scaling_labels)) + 
  geom_boxplot() + 
  geom_point() +
  xlab("Controlador") +
  ylab("Tempo de execução") +
  geom_hline(aes(yintercept=io_bound.deadline), color = "red", linetype="dashed") +
  geom_text(aes(1, io_bound.deadline, label = paste("Prazo =", io_bound.deadline), vjust = -1)) +
  scale_x_discrete(labels=scaling_labels)
save_plot("io_bound_time.png")



#
#
### IO bound - Adjusted scaling
#
#

io_bound.adjusted_scaling <- filter(aggregated_data, application == "pure_io")

#
# Written bytes
#

io_bound.adjusted_scaling$written_bytes <- as.numeric(io_bound.adjusted_scaling$written_bytes)
ggplot(io_bound.adjusted_scaling, aes(timestamp, written_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Dados escritos (em MB)") +
  facet_grid(application_conf ~ ., scales = "free_x", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound.adjusted_scaling_written.png")

#
# Read bytes
#

ggplot(io_bound.adjusted_scaling, aes(timestamp, read_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Dados lidos (em MB)") +
  facet_grid(application_conf ~ ., scales = "free_x", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound.adjusted_scaling_read.png")

#
# CPU
#

ggplot(io_bound.adjusted_scaling, aes(timestamp, cpu_usage, group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Uso de CPU") +
  facet_grid(application ~ application_conf, scales = "free", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound.adjusted_scaling_cpu.png")

#
# Cap
#

ggplot(io_bound.adjusted_scaling, aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab("Tempo") +
  ylab("Cap") +
  #facet_grid(. ~ application_conf, scales = "free",
  facet_grid(application_conf ~ ., scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound.adjusted_scaling_cap.png")

#
# Time
#

io_bound.adjusted_scaling.deadline <- deadlines["pure_io"][[1]]
ggplot(io_bound.adjusted_scaling, aes(application_conf, application_time),  
       labeller = labeller(x = scaling_labels)) + 
  geom_boxplot() + 
  geom_point() +
  xlab("Controlador") +
  ylab("Tempo de execução") +
  geom_hline(aes(yintercept=io_bound.adjusted_scaling.deadline), color = "red", linetype="dashed") +
  geom_text(aes(1, io_bound.adjusted_scaling.deadline, label = paste("Prazo =", io_bound.adjusted_scaling.deadline), vjust = -1)) +
  scale_x_discrete(labels=scaling_labels)
save_plot("io_bound.adjusted_scaling_time.png")



#
#
### IO bound - Adjusted application
#
#

io_bound.adjusted_application <- filter(aggregated_data, 
                                    application %in% c("pure_io", "pure-io-dist-adjusted") & 
                                      application_conf %in% c("pid.super_d", "pid.pd_only"))

#
# Written bytes
#

io_bound.adjusted_application$written_bytes <- as.numeric(io_bound.adjusted_application$written_bytes)
ggplot(io_bound.adjusted_application, aes(timestamp, written_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Dados escritos (em MB)") +
  facet_grid(application_conf ~ ., scales = "free_x", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound.adjusted_application_written.png")

#
# Read bytes
#

ggplot(io_bound.adjusted_application, aes(timestamp, read_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Dados lidos (em MB)") +
  facet_grid(application_conf ~ ., scales = "free_x", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound.adjusted_application_read.png")

#
# CPU
#

ggplot(io_bound.adjusted_application, aes(timestamp, cpu_usage, group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Uso de CPU") +
  facet_grid(application ~ application_conf, scales = "free", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound.adjusted_application_cpu.png")

#
# Cap
#

ggplot(io_bound.adjusted_application, aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab("Tempo") +
  ylab("Cap") +
  #facet_grid(. ~ application_conf, scales = "free",
  facet_grid(application_conf ~ ., scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound.adjusted_application_cap.png")

#
# Time
#

io_bound.adjusted_application.deadline <- deadlines["pure_io"][[1]]
ggplot(io_bound.adjusted_application, aes(application_conf, application_time),  
       labeller = labeller(x = scaling_labels)) + 
  geom_boxplot() + 
  geom_point() +
  xlab("Controlador") +
  ylab("Tempo de execução") +
  geom_hline(aes(yintercept=io_bound.adjusted_application.deadline), color = "red", linetype="dashed") +
  geom_text(aes(1, io_bound.adjusted_application.deadline, label = paste("Prazo =", io_bound.adjusted_application.deadline), vjust = -1)) +
  scale_x_discrete(labels=scaling_labels) +
  facet_wrap(~application + application_conf,
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("io_bound.adjusted_application_time.png")


#
#
### EMaaS
#
#

emaas <- filter(aggregated_data, application == "emaas")

#
# Written bytes
#

emaas$written_bytes <- as.numeric(emaas$written_bytes)
ggplot(emaas, aes(timestamp, written_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Dados escritos (em MB)") +
  facet_grid(application_conf ~ ., scales = "free_x", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("emaas_written.png")

#
# Read bytes
#

ggplot(emaas, aes(timestamp, read_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Dados lidos (em MB)") +
  facet_grid(application_conf ~ ., scales = "free_x", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("emaas_read.png")

#
# CPU
#

ggplot(emaas, aes(timestamp, cpu_usage, group = application_id)) + 
  geom_line() + 
  xlab("Tempo") +
  ylab("Uso de CPU") +
  facet_grid(application ~ application_conf, scales = "free", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("emaas_cpu.png")

#
# Cap
#

ggplot(emaas, aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab("Tempo") +
  ylab("Cap") +
  #facet_grid(. ~ application_conf, scales = "free",
  facet_grid(application_conf ~ ., scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("emaas_cap.png")

#
# Time
#

emaas.deadline <- deadlines["emaas"][[1]]
ggplot(emaas, aes(application_conf, application_time),  
       labeller = labeller(x = scaling_labels)) + 
  #geom_boxplot() + 
  geom_point() +
  #xlab("Controlador") +
  xlab("") +
  #ylab("Tempo de execução") +
  ylab("Execution time") +
  geom_hline(aes(yintercept=emaas.deadline), color = "red", linetype="dashed") +
  geom_text(aes(1, emaas.deadline, label = paste("Deadline =", emaas.deadline), vjust = -1)) +
  scale_x_discrete(labels=scaling_labels_eng)
  #+
  #facet_wrap(~application + application_conf,
  #           labeller = labeller(application = application_labels, 
  #                               application_conf = scaling_labels))
save_plot("emaas_time.png")



# For EMaaS

emaas.data <- filter(aggregated_data, application == "emaas")

ggplot(emaas.data, aes(timestamp, read_bytes/(1024*1024))) + 
  geom_line(size = 0.2) + 
  xlab("Tempo") +
  ylab("Leitura (em MB)") +
  facet_grid(instance_id ~ application_conf) 

ggplot(emaas.data, aes(timestamp, read_bytes/(1024*1024))) + 
  geom_line(size = 0.2) +
  xlab("Tempo") +
  ylab("Leitura (em MB)") +
  facet_grid(instance_id ~ actuator)

ggplot(emaas.data, aes(timestamp, written_bytes/(1024*1024))) + 
  geom_line(size = 0.2) + 
  xlab("Tempo") +
  ylab("Escrita (em MB)") +
  facet_grid(instance_id ~ application_conf)

ggplot(emaas.data, aes(timestamp, written_bytes/(1024*1024))) + 
  geom_line(size = 0.2) + 
  xlab("Tempo") +
  ylab("Escrita (em MB)") +
  facet_grid(instance_id ~ actuator)

ggplot(emaas.data, aes(timestamp, cpu_usage)) + 
  geom_line(size = 0.2) + 
  geom_step(aes(timestamp, cap), colour = "red") +
  xlab("Tempo") +
  ylab("Uso de CPU") +
  facet_grid(instance_id ~ application_conf)

ggplot(emaas.data, aes(timestamp, cpu_usage)) + 
  geom_line(size = 0.2) + 
  geom_step(aes(timestamp, cap), colour = "red") +
  xlab("Tempo") +
  ylab("Uso de CPU") +
  facet_grid(instance_id ~ actuator)


#
# Summarized results - Boxplot, etc
#

# General - Time
# TODO rename application_conf to scaling_conf
aggregated_data$application_time <- aggregated_data$application_time - 60
ggplot(aggregated_data, aes(application_conf, application_time),  labeller = labeller(x = scaling_labels)) + 
  geom_boxplot() + 
  geom_point() +
  xlab("Controlador") +
  scale_x_discrete(labels=scaling_labels) +
  ylab("Tempo de execução") +
  facet_grid(. ~ application, scales = "free", 
             labeller = labeller(variable = resources_labels, 
                                 application = application_labels))

ggsave("application_time.png")

# General - Resources
ggplot(resources_data, aes(application_conf, aggregated_cpu_usage)) + 
  geom_boxplot() + 
  geom_point() +
  xlab("Controlador") +
  ylab("Uso de CPU") +
  facet_grid(application ~ actuator, scales = "free")

ggsave("resources.png")

