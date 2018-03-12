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

theme_set(theme_bw())
theme_white()

progress_profile <- read.csv("progress_profile_aggregated.csv")
resources_profile <- read.csv("resources_profile_aggregated.csv")

resources_profile$read_bytes <- resources_profile$read_bytes/(1024*1024)
resources_profile$written_bytes <- resources_profile$written_bytes/(1024*1024)

# Application times
execution.times <- progress_profile %>% group_by(application, application_id) %>% summarize(execution_time=last(time))
application.times <- execution.times %>% group_by(application) %>% summarize(mean_execution_time=mean(execution_time), sd_execution_time=sd(execution_time))
write.csv(application.times, "application_times.csv")

# Progress - All applications
ggplot(progress_profile, aes(time, progress, group = application_id)) +
  geom_line() +
  facet_wrap(~application, scales = "free")

ggsave("progress.png")

# Read bytes - All applications
ggplot(resources_profile, aes(timestamp, read_bytes, group = application_id)) +
  geom_line() +
  facet_wrap(~application, scales = "free")

ggsave("read_bytes.png")

# Written bytes - All applications
ggplot(resources_profile, aes(timestamp, written_bytes, group = application_id)) +
  geom_line() +
  facet_wrap(~application, scales = "free")

ggsave("written_bytes.png")

# CPU usage - All applications
ggplot(resources_profile, aes(timestamp, cpu_usage, group = application_id)) +
  geom_line() +
  facet_wrap(~application, scales = "free")

ggsave("cpu.png")

# KMeans
kmeans.progress <- filter(progress_profile, application == "kmeans")
kmeans.resources <- filter(resources_profile, application == "kmeans") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
kmeans.profile <- rbind(kmeans.resources, data.frame(timestamp=kmeans.progress$time, cap=50, application="kmeans", application_id=kmeans.progress$application_id, variable="progress", value=kmeans.progress$progress))

ggplot(kmeans.progress, aes(time, progress, group = application_id)) +
  geom_line() +
  ylab("Progresso") +
  xlab("Tempo") +
  ggtitle("Progresso do KMeans")

ggplot() +
  geom_line(data=filter(kmeans.profile, variable %in% c("cpu_usage", "read_bytes", "written_bytes")), 
            aes(x = timestamp, y = value)) +
  geom_line(data=filter(kmeans.profile, variable == "progress"), 
            aes(x = timestamp, y = value, group = application_id)) + 
  ylab("") + 
  facet_grid(variable ~ application, scales = "free")

ggsave("kmeans.png", width = 8, height = 6)

# Wordcount
wordcount.progress <- filter(progress_profile, application == "wordcount")
wordcount.resources <- filter(resources_profile, application == "wordcount") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
wordcount.profile <- rbind(wordcount.resources, data.frame(timestamp=wordcount.progress$time, cap=50, application="wordcount", application_id=wordcount.progress$application_id, variable="progress", value=wordcount.progress$progress))
ggplot(filter(wordcount.profile, variable != "host_cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("") +
  facet_grid(variable ~ application, scales = "free")

ggsave("wordcount_profile.png", width = 8, height = 6)

#
# Emaas
#

emaas.progress <- filter(progress_profile, application == "emaas")
emaas.resources <- filter(resources_profile, application == "emaas") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
emaas.profile <- rbind(emaas.resources, data.frame(timestamp=emaas.progress$time, cap=50, application="emaas", application_id=emaas.progress$application_id, variable="progress", value=emaas.progress$progress))

# Only progress

ggplot(emaas.progress, aes(time, progress, group = application_id)) + 
  geom_line() +
  ylab("Progresso") +
  xlab("Tempo") +
  ggtitle("Progresso do EMaaS")

ggsave("emaas_progress.png")

# Only CPU

# Use only the first three applications
emaas.resources.sample <- filter(emaas.resources, variable == "cpu_usage" & 
                        application_id %in% unique(emaas.resources$application_id)[c(1,2,3)])
ggplot(emaas.resources.sample, aes(timestamp, 2*value, group = application_id)) + 
  geom_line() + 
  facet_grid(application_id ~ .) +
  xlab("Tempo") +
  ylab("Uso de CPU") +
  theme(
    strip.background = element_blank(),
    strip.text.y = element_blank()
  )

ggsave("emaas_cpu.png")

# Only read

# Use only the first three applications
emaas.resources.sample <- filter(emaas.resources, variable == "read_bytes" & 
                                   application_id %in% unique(emaas.resources$application_id)[c(1,2,3)])
ggplot(emaas.resources.sample, aes(timestamp, value, group = application_id)) + 
  geom_line() + 
  facet_grid(application_id ~ .) +
  xlab("Tempo") +
  ylab("Leituras (em MB)") +
  theme(
    strip.background = element_blank(),
    strip.text.y = element_blank()
  )

ggsave("emaas_read.png")

# Only written

# Use only the first three applications
emaas.resources.sample <- filter(emaas.resources, variable == "written_bytes" & 
                                   application_id %in% unique(emaas.resources$application_id)[c(1,2,3)])
ggplot(emaas.resources.sample, aes(timestamp, value, group = application_id)) + 
  geom_line() + 
  facet_grid(application_id ~ .) +
  xlab("Tempo") +
  ylab("Escritas (em MB)") +
  theme(
    strip.background = element_blank(),
    strip.text.y = element_blank()
  )

ggsave("emaas_written.png")

# All

ggplot(filter(emaas.profile, variable != "host_cpu_usage"), aes(timestamp, value, group = application_id))+
  geom_line() +
  ylab("") + 
  facet_grid(variable ~ application, scales = "free")

ggsave("emaas_profile.png", width = 8, height = 6)


#
# CPU bound scripted
#

cpubound.progress <- filter(progress_profile, application == "cpu_bound_scripted_profile")
cpubound.resources <- filter(resources_profile, application == "cpu_bound_scripted_profile") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
cpubound.profile <- rbind(cpubound.resources, data.frame(timestamp=cpubound.progress$time, cap=50, application="cpu_bound_scripted_profile", application_id=cpubound.progress$application_id, variable="progress", value=cpubound.progress$progress))
ggplot(filter(cpubound.profile, variable != "host_cpu_usage"), aes(timestamp, value, group = application_id)) +
  geom_line() +
  ylab("") +
  facet_grid(variable ~ application, scales = "free")

ggsave("cpubound_profile.png", width = 8, height = 6)
