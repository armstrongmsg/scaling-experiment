library(ggplot2)
library(dplyr)
library(reshape2)

progress_profile <- read.csv("progress_profile_aggregated.csv")
resources_profile <- read.csv("resources_profile_aggregated.csv")

# Progress
ggplot(progress_profile, aes(time, progress, group = application_id)) + 
  geom_line() + 
  facet_grid(application ~ ., scales = "free")

# KMeans
kmeans.progress <- filter(resources_profile, application == "kmeans") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
ggplot(kmeans.progress, aes(timestamp, value, group = application_id)) + 
  geom_line() + 
  facet_grid(variable ~ application, scales = "free")

# Wordcount
wordcount.progress <- filter(resources_profile, application == "wordcount") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
ggplot(wordcount.progress, aes(timestamp, value, group = application_id)) + 
  geom_line() + 
  facet_grid(variable ~ application, scales = "free")

# Emaas
emaas.progress <- filter(resources_profile, application == "emaas") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
ggplot(emaas.progress, aes(timestamp, value, group = application_id)) + 
  geom_line() + 
  facet_grid(variable ~ application, scales = "free")

# CPU bound scripted
cpubound.progress <- filter(resources_profile, application == "cpu_bound_scripted") %>% melt(id=c("timestamp", "cap", "application", "application_id"))
ggplot(cpubound.progress, aes(timestamp, value, group = application_id)) + 
  geom_line() + 
  facet_grid(variable ~ application, scales = "free")