library(ggplot2)
library(dplyr)
library(scales)

#
#
### Theme
# 
#

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

#
#
### Labels
#
#

#
# Portuguese
#

application_labels_pt <- c(cpu_bound_scripted_profile = "Aplicação limitada por CPU", 
                           cpu_bound_scripted = "Aplicação limitada por CPU",
                           cpu_bound_scripted_experiment = "Aplicação limitada por CPU",
                           emaas = "EMaaS", kmeans = "K-Means", wordcount_profile = "Wordcount", 
                           wordcount = "Wordcount", pure_io = "I/O",
                           pure_io_profile = "Aplicação limitada por IO",
                           `pure-io-dist-adjusted` = "I/O ajustada")

scaling_labels_pt <- c(pid.all = "PID", pid.pd_only = "Proporcional-\nDerivativo", 
                       pid.p_only = "Proporcional", `progress-error.regular` = "Min-Max",
                       pid.super_d = "PD ajustado", pid.super_p = "Proporcional ajustado")

actuator_labels_pt <- c(`kvm-io-tunnel` = "CPU + IO", `kvm-tunnel` = "CPU")

resources_labels_pt <- c(cpu_usage = "CPU (%)", read_bytes = "Leitura (MB)",
                      written_bytes = "Escrita (MB)", host_cpu_usage = "host_cpu_usage", 
                      progress = "Progresso")

others_pt <- c(controller = "Controlador", execution_time = "Tempo de execução", deadline = "Prazo = ", 
               time = "Tempo", cap = "Cap")

#
# English
#

application_labels_eng <- c(cpu_bound_scripted_profile = "CPU bound microbenchmark", 
                        cpu_bound_scripted = "CPU bound microbenchmark",
                        cpu_bound_scripted_experiment = "CPU bound microbenchmark",
                        emaas = "EMaaS", kmeans = "K-Means", wordcount_profile = "Wordcount", 
                        wordcount = "Wordcount", pure_io = "I/O bound microbenchmark",
                        pure_io_profile = "I/O bound microbenchmark",
                        `pure-io-dist-adjusted` = "I/O bound microbenchmark")

scaling_labels_eng <- c(pid.all = "PID", pid.pd_only = "Proportional-\nDerivative", 
                    pid.p_only = "Proportional", `progress-error.regular` = "Min-Max",
                    pid.super_d = "Proportional-Derivative", pid.super_p = "Proportional")

actuator_labels_eng <- c(`kvm-io-tunnel` = "CPU + IO", `kvm-tunnel` = "CPU")

resources_labels_eng <- c(cpu_usage = "CPU (%)", read_bytes = "Read (MB)",
                         written_bytes = "Written (MB)", host_cpu_usage = "host_cpu_usage", 
                         progress = "Progress")

others_eng <- c(controller = "Controller", execution_time = "Execution time", deadline = "Deadline = ", 
                time = "Time", cap = "Cap")

#
# Plot
#

save_plot <- function(filename) {
  ggsave(paste(PLOT_DIRECTORY, filename, sep = "/"), width = 11, height = 6)
}

#
#
### "init"
#
#

# --------------------------------------------------------------------------

if (exists("language")) {
  if (language == "pt") {
    resource_labels <- resources_labels_pt
    scaling_labels <- scaling_labels_pt
    application_labels <- application_labels_pt
    actuator_labels <- actuator_labels_pt
    other_labels <- others_pt
  } else if (language == "eng") {
    resource_labels <- resources_labels_eng
    scaling_labels <- scaling_labels_eng
    application_labels <- application_labels_eng
    actuator_labels <- actuator_labels_eng
    other_labels <- others_eng
  }
} else {
  warning("Language is not set")
}

theme_set(theme_bw())
theme_white()

PLOT_DIRECTORY <- "emaas"
deadlines <- c(cpu_bound_scripted = 2060, pure_io = 2733, emaas = 2347)

aggregated_data <- read.csv("aggregated.csv")
resources_data <- read.csv("resources.csv")

# --------------------------------------------------------------------------

#
#
### CPU bound 
#
#

cpu_bound <- filter(aggregated_data, application == "cpu_bound_scripted_experiment")

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
  xlab("Time") +
  ylab("Cap") +
  facet_grid(application ~ application_conf, scales = "free",
             labeller = labeller(application = application_labels_eng, 
                                 application_conf = scaling_labels_eng))
save_plot("cpu_bound_cap.png")

#
# Time
#

cpu_bound.deadline <- deadlines["cpu_bound_scripted"][[1]]
ggplot(cpu_bound, aes(application_conf, application_time),  
                labeller = labeller(x = scaling_labels_eng)) + 
  geom_boxplot() + 
  geom_point() +
  xlab("Controller") +
  ylab("Execution time") +
  geom_hline(aes(yintercept=cpu_bound.deadline), color = "red", linetype="dashed") +
  geom_text(aes(1, cpu_bound.deadline, label = paste("Deadline =", cpu_bound.deadline), vjust = -1)) +
  scale_x_discrete(labels=scaling_labels_eng)
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

ggplot(emaas, aes(timestamp, written_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab(other_labels["time"][[1]]) +
  ylab(resource_labels["written_bytes"][[1]]) +
  facet_grid(application_conf ~ ., scales = "free_x", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("emaas_written.png")

#
# Read bytes
#

ggplot(emaas, aes(timestamp, read_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  xlab(other_labels["time"][[1]]) +
  ylab(resource_labels["read_bytes"][[1]]) +
  facet_grid(application_conf ~ ., scales = "free_x", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("emaas_read.png")

#
# CPU
#

ggplot(emaas, aes(timestamp, cpu_usage, group = application_id)) + 
  geom_line() + 
  xlab(other_labels["time"][[1]]) +
  ylab(resource_labels["cpu_usage"][[1]]) +
  facet_grid(application ~ application_conf, scales = "free", 
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("emaas_cpu.png")

#
# Cap
#

ggplot(filter(emaas, instance_id %in% unique(emaas$instance_id)[c(1,13)]) , aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab(other_labels["time"][[1]]) +
  ylab(other_labels["cap"][[1]]) +
  facet_grid(application ~ application_conf, scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("emaas_cap.png")

#
# Time
#

emaas.deadline <- deadlines["emaas"][[1]]
emaas.time <- group_by(emaas, application_conf, actuator, application_id) %>% 
              summarize(application_time = mean(application_time))
ggplot(emaas.time, aes(application_conf, application_time)) + 
  geom_boxplot(width = 0.3) + 
  geom_point() +
  xlab("") +
  ylab(other_labels["execution_time"][[1]]) +
  geom_hline(aes(yintercept=emaas.deadline), color = "red", linetype="dashed") +
  geom_text(aes(1, emaas.deadline, label = paste(other_labels["deadline"][[1]], 
                                                 emaas.deadline), vjust = -1)) +
  scale_x_discrete(labels = scaling_labels) +
  facet_grid(actuator ~ ., labeller = labeller(actuator = actuator_labels))

save_plot("emaas_time.png")

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

