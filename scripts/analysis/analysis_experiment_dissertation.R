library(ggplot2)
library(dplyr)

aggregated_data <- read.csv("aggregated.csv")
resources_data <- read.csv("resources.csv")

#
# Resources usage - Time Series
#

# TODO complete this filtering
spark_applications <- filter(aggregated_data, application == "kmeans")
os_generic_application <- filter(aggregated_data, application == "cpu_bound_scripted" | application == "wordcount")

ggplot(spark_applications, aes(timestamp, written_bytes, group = application_id)) + 
  geom_line() + 
  facet_grid(application ~ instance_id)

ggplot(os_generic_application, aes(timestamp, written_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  facet_grid(application ~ ., scales = "free")

ggplot(os_generic_application, aes(timestamp, read_bytes/(1024*1024), group = application_id)) + 
  geom_line() + 
  facet_grid(application ~ ., scales = "free")


ggplot(aggregated_data, aes(timestamp, read_bytes)) + 
  geom_line() + 
  facet_grid(. ~ instance_id)

ggplot(aggregated_data, aes(timestamp, cpu_usage, colour = application_id)) + 
  geom_line() + 
  facet_grid(instance_id ~ application)

#
# Summarized results - Boxplot, etc
#

# General - Time
# TODO rename application_conf to scaling_conf
ggplot(aggregated_data, aes(application_conf, application_time)) + 
  geom_boxplot() + 
  geom_point() +
  facet_grid(application ~ actuator, scales = "free")

# General - Resources
ggplot(resources_data, aes(application_conf, aggregated_cpu_usage)) + 
  geom_boxplot() + 
  geom_point() +
  facet_grid(application ~ actuator, scales = "free")