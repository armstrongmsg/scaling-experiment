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
    axis.text.x = element_text(size=15, angle = 0),
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
                           wordcount = "Wordcount", pure_io = "Aplicação limitada por I/O",
                           pure_io_profile = "Aplicação limitada por I/O",
                           `pure-io-dist-adjusted` = "I/O ajustada")

scaling_labels_pt <- c(pid.all = "PID", pid.pd_only = "Proporcional-Derivativo", 
                       pid.p_only = "Proporcional", `progress-error.regular` = "Min-Max",
                       pid.super_d = "Proporcional-Derivativo ajustado", 
                       pid.super_p = "Proporcional ajustado",
                       no_controller = "Sem controlador")

actuator_labels_pt <- c(`kvm-io-tunnel` = "CPU + IO", `kvm-tunnel` = "CPU")

resources_labels_pt <- c(cpu_usage = "CPU (%)", read_bytes = "Leitura (MB)",
                         written_bytes = "Escrita (MB)", host_cpu_usage = "host_cpu_usage", 
                         progress = "Progresso")

others_pt <- c(controller = "Controlador", execution_time = "Tempo de execução (s)", 
               deadline = "Prazo em segundos = ", 
               time = "Tempo (s)", cap = "Cap (%)")

#
# English
#

application_labels_eng <- c(cpu_bound_scripted_profile = "CPU bound microbenchmark", 
                            cpu_bound_scripted = "CPU bound microbenchmark",
                            cpu_bound_scripted_experiment = "CPU bound microbenchmark",
                            emaas = "EMaaS", kmeans = "K-Means", wordcount_profile = "Wordcount", 
                            wordcount = "Wordcount", pure_io = "I/O",
                            pure_io_profile = "I/O bound microbenchmark",
                            `pure-io-dist-adjusted` = "Linearization")

scaling_labels_eng <- c(pid.all = "PID", pid.pd_only = "PD", 
                        pid.p_only = "P", `progress-error.regular` = "Min-Max",
                        pid.super_d = "Adjusted PD", pid.super_p = "Proportional", 
                        `pure-io-dist-adjusted` = "Linearization", 
                        `no_controller` = "None")

actuator_labels_eng <- c(`kvm-io-tunnel` = "CPU + IO", `kvm-tunnel` = "CPU")

resources_labels_eng <- c(cpu_usage = "CPU (%)", read_bytes = "Read (MB)",
                          written_bytes = "Written (MB)", host_cpu_usage = "host_cpu_usage", 
                          progress = "Progress")

others_eng <- c(controller = "Controller", execution_time = "Execution time (s)", 
                deadline = "Deadline (in seconds) = ", 
                time = "Time (s)", cap = "Cap (%)")

#
# Plot
#

save_plot <- function(filename) {
  ggsave(paste(PLOT_DIRECTORY, filename, sep = "/"), width = 6, height = 6)
}

#
#
### "init"
#
#

# --------------------------------------------------------------------------

PLOT_DIRECTORY <- "plots_paper"
deadlines <- c(cpu_bound_scripted = 2060, pure_io = 2733, emaas = 2347)

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



aggregated_data <- read.csv("aggregated.csv")
resources_data <- read.csv("resources.csv")
application.times <- read.csv("application_times.csv")



# --------------------------------------------------------------------------

#
#
### CPU bound 
#
#

cpu_bound <- filter(aggregated_data, application == "cpu_bound_scripted_experiment")

#
# Cap
#

ggplot(cpu_bound, aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab(other_labels["time"][[1]]) +
  ylab(other_labels["cap"][[1]]) +
  facet_grid(application_conf ~ ., scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))
save_plot("cpu_bound_cap.png")

#
# Time
#

cpu_bound.times <- unique(select(cpu_bound, application_id, 
                          application_time, application_conf))
cpu_bound_no_controller.times <- filter(application.times, 
                                        application == "cpu_bound_scripted_experiment_dist")
cpu_bound.times <- rbind(cpu_bound.times, 
                         data.frame(application_id="1",
                                    application_time=cpu_bound_no_controller.times$execution_time, 
                                    application_conf="no_controller"))

cpu_bound.deadline <- deadlines["cpu_bound_scripted"][[1]]

ggplot(cpu_bound.times, aes(application_conf, application_time),  
       labeller = labeller(x = scaling_labels_eng)) + 
  geom_boxplot() + 
  geom_point() +
  xlab(other_labels["controller"][[1]]) +
  ylab(other_labels["execution_time"][[1]]) +
  geom_hline(aes(yintercept=cpu_bound.deadline), color = "red", linetype="dashed") +
  geom_text(aes(2, cpu_bound.deadline, label = paste(other_labels["deadline"][[1]], 
                                                     cpu_bound.deadline), vjust = -1)) +
  scale_x_discrete(labels=scaling_labels)


save_plot("cpu_bound_time.png")




#
#
### IO bound 
#
#

io_bound <- filter(aggregated_data, application == "pure_io" & 
                     application_conf != "pid.super_d")

#
# Cap
#

ggplot(io_bound, aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab(other_labels["time"][[1]]) +
  ylab(other_labels["cap"][[1]]) +
  facet_grid(application_conf ~ ., scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels))

save_plot("io_bound_cap.png")

#
# Time
#

# Add no controller times to the main data frame

io_bound.times <- unique(select(io_bound, application_id, 
                                application_time, application_conf))
io_bound_no_controller.times <- filter(application.times, application == "pure_io")
io_bound.times <- rbind(io_bound.times, 
                        data.frame(application_id="1",
                                   application_time=io_bound_no_controller.times$execution_time, 
                                   application_conf="no_controller"))

io_bound.deadline <- deadlines["pure_io"][[1]]

ggplot(io_bound.times, aes(application_conf, application_time),  
       labeller = labeller(x = scaling_labels)) + 
  geom_boxplot() + 
  geom_point() +
  xlab(other_labels["controller"][[1]]) +
  ylab(other_labels["execution_time"][[1]]) +
  geom_hline(aes(yintercept=io_bound.deadline), color = "red", linetype="dashed") +
  geom_text(aes(2, io_bound.deadline, label = paste(other_labels["deadline"][[1]], 
                                                    io_bound.deadline), vjust = -1))  +
  scale_x_discrete(labels=scaling_labels)

save_plot("io_bound_time.png")




#
#
### IO bound - Adjusted scaling
#
#

io_bound.adjusted_scaling <- filter(aggregated_data, application %in% c("pure_io", "pure-io-dist-adjusted") & 
                                     application_conf %in% c("pid.pd_only", "pid.super_d"))
                                      
                                      
                                    #    (application == )
                                    #  &&
                                    # (application_conf == "pid.pd_only") |
                                    #   (application_conf == "pid.super_d") )

#
# Cap
#

ggplot(io_bound.adjusted_scaling, aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab(other_labels["time"][[1]]) +
  ylab(other_labels["cap"][[1]]) +
  facet_wrap(~ application_conf + application, ncol=1, scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels), strip.position="right")

save_plot("io_bound.adjusted_cap.png")

#
# Time
#

io_bound.adjusted_pd <- filter(io_bound.adjusted_scaling, application_conf == "pid.super_d")
io_bound.adjusted_io <- filter(io_bound.adjusted_scaling, (application_conf == "pid.pd_only") & 
                                 (application == "pure-io-dist-adjusted"))
io_bound.old <- filter(io_bound.adjusted_scaling, application_conf == "pid.pd_only" & 
                         application == "pure_io")

ggplot() + 
  geom_boxplot(data = io_bound.adjusted_pd, aes(application_conf, application_time)) + 
  geom_boxplot(data = io_bound.adjusted_io, aes(application, application_time)) +
  geom_boxplot(data = io_bound.old, aes(application_conf, application_time)) +
  geom_point(data = io_bound.adjusted_pd, aes(application_conf, application_time)) + 
  geom_point(data = io_bound.adjusted_io, aes(application, application_time)) +
  geom_point(data = io_bound.old, aes(application_conf, application_time)) +
  xlab("") +
  ylab(other_labels["execution_time"][[1]]) +
  geom_hline(aes(yintercept=io_bound.deadline), color = "red", linetype="dashed") +
  geom_text(aes(1.2, io_bound.deadline, label = paste(other_labels["deadline"][[1]], 
                                                      io_bound.deadline), vjust = -1))  +
  scale_x_discrete(labels=scaling_labels)


save_plot("io_bound.adjusted_time.png")




#
#
### EMaaS
#
#

emaas <- filter(aggregated_data, application == "emaas" &
                application_conf %in% c("pid.p_only", "pid.pd_only", "progress-error.regular"))

#
# Cap
#

ggplot(filter(emaas, instance_id %in% unique(emaas$instance_id)[c(1,13)]) , 
       aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab(other_labels["time"][[1]]) +
  ylab(other_labels["cap"][[1]]) +
  facet_grid(application_conf ~ ., scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels,
                                 actuator = actuator_labels))

save_plot("emaas_cap.png")

#
# Time
#

# Add no controller times to the main data frame

emaas_no_controller.times <- filter(application.times, application == "emaas")
emaas.time <- select(emaas, application_conf, actuator, application_id, application_time)
emaas.time <- rbind(emaas.time, 
                          data.frame(application_conf="no_controller", 
                                     actuator="kvm-io-tunnel", 
                                     application_id=as.character(1:10),
                                     application_time=as.numeric(emaas_no_controller.times$execution_time)), 
                          data.frame(application_conf="no_controller", 
                                     actuator="kvm-tunnel", 
                                     application_id=as.character(11:20),
                                     application_time=as.numeric(emaas_no_controller.times$execution_time)
                                     ))

emaas.deadline <- deadlines["emaas"][[1]]
emaas.time <- emaas.time %>% group_by(application_conf, actuator, application_id) %>% 
  summarize(application_time = mean(application_time))
ggplot(emaas.time, aes(application_conf, application_time)) + 
  geom_boxplot(width = 0.3) + 
  geom_point() +
  xlab("") +
  ylab(other_labels["execution_time"][[1]]) +
  geom_hline(aes(yintercept=emaas.deadline), color = "red", linetype="dashed") +
  geom_text(aes(1.5, emaas.deadline, label = paste(other_labels["deadline"][[1]], 
                                                 emaas.deadline), vjust = -1)) +
  scale_x_discrete(labels = scaling_labels) +
  facet_grid(actuator ~ ., labeller = labeller(actuator = actuator_labels))

save_plot("emaas_time.png")




#
#
### EMaaS - Adjusted
#
#

emaas.adjusted.derivative <- filter(aggregated_data, application == "emaas" &
                                      application_conf %in% c("pid.super_d", "pid.pd_only"))

#
# Cap
#

ggplot(filter(emaas.adjusted.derivative, 
              instance_id %in% unique(emaas.adjusted.derivative$instance_id)[c(1,13,26)]), 
              aes(timestamp, cap, group = application_id)) + 
  geom_line() +
  xlab(other_labels["time"][[1]]) +
  ylab(other_labels["cap"][[1]]) +
  facet_grid(application_conf ~ application, scales = "free",
             labeller = labeller(application = application_labels, 
                                 application_conf = scaling_labels,
                                 actuator = actuator_labels))

save_plot("emaas_cap_adjusted_derivative.png")

#
# Time
#

emaas.time.adjusted.derivative <- group_by(emaas.adjusted.derivative, 
                                           application_conf, actuator, application_id) %>% 
  summarize(application_time = mean(application_time))
ggplot(emaas.time.adjusted.derivative, aes(application_conf, application_time)) + 
  geom_boxplot(width = 0.3) + 
  geom_point() +
  xlab("") +
  ylab(other_labels["execution_time"][[1]]) +
  geom_hline(aes(yintercept=emaas.deadline), color = "red", linetype="dashed") +
  geom_text(aes(1, emaas.deadline, label = paste(other_labels["deadline"][[1]], 
                                                 emaas.deadline), vjust = -1)) +
  scale_x_discrete(labels = scaling_labels) +
  facet_grid(actuator ~ ., labeller = labeller(actuator = actuator_labels))

save_plot("emaas_time_adjusted_derivative.png")
