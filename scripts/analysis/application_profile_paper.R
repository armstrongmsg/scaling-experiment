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
  ggsave(paste(PLOT_DIRECTORY, filename, sep = "/"), width = 6, height = 6)
}

resources_labels <- c(cpu_usage = "CPU (%)", read_bytes = "Leitura (MB)",
                      written_bytes = "Escrita (MB)", host_cpu_usage = "host_cpu_usage", 
                      progress = "Progresso")

application_labels <- c(cpu_bound_scripted_experiment = "Aplicação limitada por CPU", 
                        cpu_bound_scripted_experiment_dist = "CPU",
                        cpu_bound_scripted = "Aplicação limitada por CPU",
                        emaas = "EMaaS", kmeans = "K-Means", wordcount_profile = "Wordcount", 
                        wordcount = "Wordcount", pure_io = "I/O",
                        pure_io_profile = "I/O")

PLOT_DIRECTORY <- "plots_paper"

theme_set(theme_bw())
theme_white()

dir.create(PLOT_DIRECTORY)

progress_profile <- read.csv("progress_profile_aggregated.csv")
resources_profile <- read.csv("resources_profile_aggregated.csv")

resources_profile$read_bytes <- resources_profile$read_bytes/(1024*1024)
resources_profile$written_bytes <- resources_profile$written_bytes/(1024*1024)
resources_profile$cpu_usage <- resources_profile$cpu_usage*100/resources_profile$cap

# Application times
execution.times <- progress_profile %>% group_by(application, application_id) %>% 
                                          summarize(execution_time=last(time))
application.times <- execution.times %>% group_by(application) %>% 
                                          summarize(mean_execution_time=mean(execution_time), 
                                                    sd_execution_time=sd(execution_time))
write.csv(application.times, "application_times.csv")
write.csv(execution.times, "application_times.csv")

#
# Progress - All applications
#

progress_profile_paper <- filter(progress_profile, application %in% 
                                   c("cpu_bound_scripted_experiment_dist", "pure_io", "emaas"))
no_disturbance <- filter(progress_profile, application %in% 
                                   c("cpu_bound_scripted_experiment", "pure_io_profile"))

no_disturbance[no_disturbance=="cpu_bound_scripted_experiment"]<-"cpu_bound_scripted_experiment_dist"
no_disturbance[no_disturbance=="pure_io_profile"]<-"pure_io"

no_disturbance <- filter(no_disturbance, application_id != "osgeneric7")

ggplot(progress_profile_paper, aes(time, progress*100)) +
  geom_line(aes(group = application_id)) +
  geom_line(data = no_disturbance, aes(time, progress*100, group = application_id), colour = "red") +
  xlab("Time (s)") +
  ylab("Progress (%)") +
  facet_wrap(~factor(application,levels=c("cpu_bound_scripted_experiment_dist", "pure_io", "emaas"), 
                     labels=c("CPU", "I/O", "EMaaS")), 
             scales = "free", ncol=1, strip.position="right", 
             labeller = labeller(variable = resources_labels, application = application_labels))
  

save_plot("progress.png")
