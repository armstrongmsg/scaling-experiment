library(ggplot2)
library(dplyr)
library(reshape2)

theme_white <- function() {
  theme_update(
    plot.title = element_text(size=14, hjust = 0.5),
    axis.text.y =element_text(size=10),
    axis.title = element_text(size=17),
    legend.title = element_text(size = 16),
    legend.text = element_text(size = 14),
    axis.text.x = element_text(size=18, angle = 0, hjust = 1),
    strip.text.y = element_text(size = 12, angle = 90),
    strip.text.x = element_text(size = 18, angle = 0)
  )
}

save_plot <- function(filename) {
  ggsave(paste(PLOT_DIRECTORY, filename, sep = "/"), width = 10, height = 7)
}

resources_labels <- c(cpu_usage = "CPU (%)", read_bytes = "Leitura (MB)",
                      written_bytes = "Escrita (MB)", host_cpu_usage = "host_cpu_usage", 
                      progress = "Progresso")

application_labels <- c(cpu_bound_scripted_experiment = "Aplicação limitada por CPU", 
                        cpu_bound_scripted = "Aplicação limitada por CPU",
                        emaas = "EMaaS", kmeans = "K-Means", wordcount_profile = "Wordcount", 
                        wordcount = "Wordcount", pure_io = "Aplicação limitada por IO",
                        pure_io_profile = "Aplicação limitada por IO")

PLOT_DIRECTORY <- "emaas"

theme_set(theme_bw())
theme_white()

dir.create(PLOT_DIRECTORY)

progress_profile <- read.csv("progress_profile_aggregated.csv")
resources_profile <- read.csv("resources_profile_aggregated.csv")

resources_profile$read_bytes <- resources_profile$read_bytes/(1024*1024)
resources_profile$written_bytes <- resources_profile$written_bytes/(1024*1024)
resources_profile$cpu_usage <- resources_profile$cpu_usage*100/resources_profile$cap

# Application times
execution.times <- progress_profile %>% group_by(application, application_id) %>% summarize(execution_time=last(time))
application.times <- execution.times %>% group_by(application) %>% summarize(mean_execution_time=mean(execution_time), sd_execution_time=sd(execution_time))
write.csv(application.times, "application_times.csv")

#
# Progress - All applications
#

ggplot(progress_profile, aes(time, progress, group = application_id)) +
  geom_line() +
  facet_wrap(~application, scales = "free", 
             labeller = labeller(variable = resources_labels, 
                                 application = application_labels))

save_plot("progress.png")

#
# Read bytes - All applications
#

ggplot(resources_profile, aes(timestamp, read_bytes, group = application_id)) +
  geom_line() +
  facet_wrap(~application, scales = "free", 
             labeller = labeller(variable = resources_labels, 
                                 application = application_labels))

save_plot("read_bytes.png")

#
# Written bytes - All applications
#

ggplot(resources_profile, aes(timestamp, written_bytes, group = application_id)) +
  geom_line() +
  facet_wrap(~application, scales = "free")

save_plot("written_bytes.png")

#
# CPU usage - All applications
#

ggplot(resources_profile, aes(timestamp, cpu_usage, group = application_id)) +
  geom_line() +
  facet_wrap(~application, scales = "free")

save_plot("cpu.png")

#
# KMeans
#

kmeans.progress <- filter(progress_profile, application == "kmeans")
kmeans.resources <- filter(resources_profile, application == "kmeans") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
kmeans.profile <- rbind(kmeans.resources, data.frame(timestamp=kmeans.progress$time, cap=50, application="kmeans", application_id=kmeans.progress$application_id, variable="progress", value=kmeans.progress$progress))

ggplot(filter(kmeans.profile, variable != "host_cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("") +
  xlab("Tempo (s)") + 
  facet_grid(variable ~ application, scales = "free", 
             labeller = labeller(variable = resources_labels, 
                                 application = application_labels))

save_plot("kmeans.png")

ggplot(filter(kmeans.profile, variable == "cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Uso de CPU (%)") +
  xlab("Tempo (s)")

save_plot("cpu_kmeans.png")

ggplot(filter(kmeans.profile, variable == "read_bytes"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados lidos (em MB)") +
  xlab("Tempo (s)")

save_plot("read_bytes_kmeans.png")

ggplot(filter(kmeans.profile, variable == "written_bytes"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados escritos (em MB)") +
  xlab("Tempo (s)")

save_plot("written_bytes_kmeans.png")

ggplot(filter(kmeans.profile, variable == "progress"), aes(timestamp, 100*value, group = application_id)) +
  geom_line() +
  ylab("Progresso (em %)") +
  xlab("Tempo (s)")

save_plot("progress_kmeans.png")

#
# Wordcount (sem perturbação)
#

wordcount.progress <- filter(progress_profile, application == "wordcount_profile")
wordcount.resources <- filter(resources_profile, application == "wordcount_profile") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
wordcount.profile <- rbind(wordcount.resources, 
                           data.frame(timestamp=wordcount.progress$time, cap=50, application="wordcount_profile", 
                                      application_id=wordcount.progress$application_id, variable="progress", 
                                      value=wordcount.progress$progress))
ggplot(filter(wordcount.profile, variable != "host_cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("") +
  facet_grid(variable ~ application, scales = "free",
             labeller = labeller(variable = resources_labels, 
                                 application = application_labels))

save_plot("wordcount_sem_perturbacao.png")

ggplot(filter(wordcount.profile, variable == "cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Uso de CPU (%)") +
  xlab("Tempo (s)")

save_plot("cpu_wordcount_sem_perturbacao.png")

ggplot(filter(wordcount.profile, variable == "read_bytes"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados lidos (em MB)") +
  xlab("Tempo (s)")

save_plot("read_bytes_wordcount_sem_perturbacao.png")

ggplot(filter(wordcount.profile, variable == "written_bytes"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados escritos (em MB)") +
  xlab("Tempo (s)")

save_plot("written_bytes_wordcount_sem_perturbacao.png")

ggplot(filter(wordcount.profile, variable == "progress"), aes(timestamp, 100*value, group = application_id)) +
  geom_line() +
  ylab("Progresso (em %)") +
  xlab("Tempo (s)")

save_plot("progress_wordcount_sem_perturbacao.png")

#
# Emaas
#

emaas.progress <- filter(progress_profile, application == "emaas")
emaas.resources <- filter(resources_profile, application == "emaas") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
emaas.profile <- rbind(emaas.resources, data.frame(timestamp=emaas.progress$time, cap=70, application="emaas", application_id=emaas.progress$application_id, variable="progress", value=emaas.progress$progress))

ggplot(emaas.progress, aes(time, 100*progress, group = application_id)) + 
  geom_line() +
  ylab("Progresso (em %)") +
  xlab("Tempo (s)")

save_plot("emaas_progress.png")

# Use only the first three applications
emaas.resources.sample <- filter(emaas.resources, variable == "cpu_usage" & 
                        application_id %in% unique(emaas.resources$application_id)[c(1,2,3)])
emaas.resources.sample <- filter(emaas.resources.sample, emaas.resources.sample$value <= 100)
ggplot(emaas.resources.sample, aes(timestamp, value, group = application_id)) + 
  geom_line() + 
  facet_grid(application_id ~ .) +
  xlab("Tempo (s)") +
  ylab("Uso de CPU (%)")

save_plot("emaas_cpu.png")

# Use only the first three applications
emaas.resources.sample <- filter(emaas.resources, variable == "read_bytes" & 
                                   application_id %in% unique(emaas.resources$application_id)[c(1,2,3)])
ggplot(emaas.resources.sample, aes(timestamp, value, group = application_id)) + 
  geom_line() + 
  facet_grid(application_id ~ .) +
  ylab("Dados lidos (em MB)") +
  xlab("Tempo (s)")

save_plot("emaas_read.png")

# Use only the first three applications
emaas.resources.sample <- filter(emaas.resources, variable == "written_bytes" & 
                                   application_id %in% unique(emaas.resources$application_id)[c(1,2,3)])
ggplot(emaas.resources.sample, aes(timestamp, value, group = application_id)) + 
  geom_line() + 
  facet_grid(application_id ~ .) +
  ylab("Dados escritos (em MB)") +
  xlab("Tempo (s)")

save_plot("emaas_written.png")


#
# CPU bound scripted (sem perturbações)
#

cpubound.progress <- filter(progress_profile, application == "cpu_bound_scripted_experiment")
cpubound.resources <- filter(resources_profile, application == "cpu_bound_scripted_experiment") %>% 
                      melt(id=c("timestamp", "cap", "application", "application_id"))

cpubound.profile <- rbind(cpubound.resources, 
                          data.frame(timestamp=cpubound.progress$time, cap=50, 
                                     application="cpu_bound_scripted_experiment", 
                                     application_id=cpubound.progress$application_id, 
                                     variable="progress", value=cpubound.progress$progress))

ggplot(filter(cpubound.profile, variable != "host_cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("") +
  xlab("Tempo (s)") + 
  facet_grid(variable ~ application, scales = "free", 
             labeller = labeller(variable = resources_labels, 
                                 application = application_labels))

save_plot("cpubound_sem_perturbacao.png")

ggplot(filter(cpubound.profile, variable == "cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Uso de CPU (%)") +
  xlab("Tempo (s)")

save_plot("cpu_cpubound_sem_perturbacao.png")

ggplot(filter(cpubound.profile, variable == "read_bytes"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados lidos (em MB)") +
  xlab("Tempo (s)")

save_plot("read_bytes_cpubound_sem_perturbacao.png")

ggplot(filter(cpubound.profile, variable == "written_bytes"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados escritos (em MB)") +
  xlab("Tempo (s)")

save_plot("written_bytes_cpubound_sem_perturbacao.png")

ggplot(filter(cpubound.profile, variable == "progress"), aes(timestamp, 100*value, group = application_id)) +
  geom_line() +
  ylab("Progresso (em %)") +
  xlab("Tempo (s)")

save_plot("progress_cpubound_sem_perturbacao.png")


#
# CPU bound scripted (com perturbações)
#

cpubound_dist.progress <- filter(progress_profile, application == "cpu_bound_scripted_experiment_dist")
cpubound_dist.resources <- filter(resources_profile, application == "cpu_bound_scripted_experiment_dist") %>% 
  melt(id=c("timestamp", "cap", "application", "application_id"))

cpubound_dist.profile <- rbind(cpubound_dist.resources, 
                          data.frame(timestamp=cpubound_dist.progress$time, cap=50, 
                                     application="cpu_bound_scripted_experiment_dist", 
                                     application_id=cpubound_dist.progress$application_id, 
                                     variable="progress", value=cpubound_dist.progress$progress))

ggplot(filter(cpubound_dist.profile, variable != "host_cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("") +
  xlab("Tempo (s)") + 
  facet_grid(variable ~ application, scales = "free", 
             labeller = labeller(variable = resources_labels, 
                                 application = application_labels))

save_plot("cpubound_com_perturbacao.png")

ggplot(filter(cpubound_dist.profile, variable == "cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Uso de CPU (%)") +
  xlab("Tempo (s)")

save_plot("cpu_cpubound_com_perturbacao.png")

ggplot(filter(cpubound_dist.profile, variable == "read_bytes"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados lidos (em MB)") +
  xlab("Tempo (s)")

save_plot("read_bytes_cpubound_com_perturbacao.png")

ggplot(filter(cpubound_dist.profile, variable == "written_bytes"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados escritos (em MB)") +
  xlab("Tempo (s)")

save_plot("written_bytes_cpubound_com_perturbacao.png")

ggplot(filter(cpubound_dist.profile, variable == "progress"), aes(timestamp, 100*value, group = application_id)) +
  geom_line() +
  ylab("Progresso (em %)") +
  xlab("Tempo (s)")

save_plot("progress_cpubound_com_perturbacao.png")


#
# IO bound scripted (sem perturbações)
#

pure_io.progress <- filter(progress_profile, application == "pure_io_profile")
pure_io.resources <- filter(resources_profile, application == "pure_io_profile") %>% 
  melt(id=c("timestamp", "cap", "application", "application_id"))

pure_io.profile <- rbind(pure_io.resources, 
                          data.frame(timestamp=pure_io.progress$time, cap=50, 
                                     application="pure_io_profile", 
                                     application_id=pure_io.progress$application_id, 
                                     variable="progress", value=pure_io.progress$progress))

ggplot(filter(pure_io.profile, variable != "host_cpu_usage" & application_id != "osgeneric7"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("") +
  xlab("Tempo (s)") + 
  facet_grid(variable ~ application, scales = "free", 
             labeller = labeller(variable = resources_labels, 
                                 application = application_labels))

save_plot("pure_io_sem_perturbacao.png")

ggplot(filter(pure_io.profile, variable == "cpu_usage" & application_id != "osgeneric7"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Uso de CPU (%)") +
  xlab("Tempo (s)")

save_plot("cpu_pure_io_sem_perturbacao.png")

ggplot(filter(pure_io.profile, variable == "read_bytes" & application_id != "osgeneric7"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados lidos (em MB)") +
  xlab("Tempo (s)")

save_plot("read_bytes_pure_io_sem_perturbacao.png")

ggplot(filter(pure_io.profile, variable == "written_bytes" & application_id != "osgeneric7"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados escritos (em MB)") +
  xlab("Tempo (s)")

save_plot("written_bytes_pure_io_sem_perturbacao.png")

ggplot(filter(pure_io.profile, variable == "progress" & application_id != "osgeneric7"), aes(timestamp, 100*value, group = application_id)) +
  geom_line() +
  ylab("Progresso (em %)") +
  xlab("Tempo (s)")

save_plot("progress_pure_io_sem_perturbacao.png")


#
# IO bound scripted (com perturbações)
#

pure_io_dist.progress <- filter(progress_profile, application == "pure_io")
pure_io_dist.resources <- filter(resources_profile, application == "pure_io") %>% 
  melt(id=c("timestamp", "cap", "application", "application_id"))

pure_io_dist.profile <- rbind(pure_io_dist.resources, 
                               data.frame(timestamp=pure_io_dist.progress$time, cap=50, 
                                          application="pure_io", 
                                          application_id=pure_io_dist.progress$application_id, 
                                          variable="progress", value=pure_io_dist.progress$progress))

ggplot(filter(pure_io_dist.profile, variable != "host_cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("") +
  xlab("Tempo (s)") + 
  facet_grid(variable ~ application, scales = "free", 
             labeller = labeller(variable = resources_labels, 
                                 application = application_labels))

save_plot("pure_io_com_perturbacao.png")

ggplot(filter(pure_io_dist.profile, variable == "cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Uso de CPU (%)") +
  xlab("Tempo (s)")

save_plot("cpu_pure_io_com_perturbacao.png")

ggplot(filter(pure_io_dist.profile, variable == "read_bytes"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados lidos (em MB)") +
  xlab("Tempo (s)")

save_plot("read_bytes_pure_io_com_perturbacao.png")

ggplot(filter(pure_io_dist.profile, variable == "written_bytes"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("Dados escritos (em MB)") +
  xlab("Tempo (s)")

save_plot("written_bytes_pure_io_com_perturbacao.png")

ggplot(filter(pure_io_dist.profile, variable == "progress"), aes(timestamp, 100*value, group = application_id)) +
  geom_line() +
  ylab("Progresso (em %)") +
  xlab("Tempo (s)")

save_plot("progress_pure_io_com_perturbacao.png")





