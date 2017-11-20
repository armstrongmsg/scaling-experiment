library(ggplot2)
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

theme_set(theme_bw())
theme_white()

aggregated_data <- read.csv("aggregated.csv")
resources_data <- read.csv("resources.csv")

aggregated_data$application_conf <- factor(aggregated_data$application_conf, labels = c("min-max", "proporcional-derivativo", "proporcional"))
resources_data$application_conf <- factor(resources_data$application_conf, labels = c("min-max", "proporcional-derivativo", "proporcional"))

aggregated_data$actuator <- factor(aggregated_data$actuator, labels = c("CPU + I/O", "CPU"))
resources_data$actuator <- factor(resources_data$actuator, labels = c("CPU + I/O", "CPU"))

#
# Resources usage - Time Series
#

# TODO complete this filtering
spark_applications <- filter(aggregated_data, application == "kmeans" | application == "emaas")
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


ggplot(filter(aggregated_data, application_id == "osspark17"), aes(timestamp, read_bytes/(1024*1024))) + 
  geom_line() + 
  geom_point() +
  facet_grid(. ~ instance_id)

ggplot(filter(aggregated_data, application_id == "osspark17"), aes(timestamp, written_bytes/(1024*1024))) + 
  geom_line() + 
  geom_point() +
  facet_grid(. ~ instance_id)

ggplot(filter(aggregated_data, application_id == "osspark17"), aes(timestamp, cpu_usage)) + 
  geom_line() + 
  geom_point() +
  facet_grid(instance_id ~ application)


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
ggplot(aggregated_data, aes(application_conf, application_time)) + 
  geom_boxplot() + 
  geom_point() +
  xlab("Controlador") +
  ylab("Tempo de execução") +
  facet_grid(application ~ actuator, scales = "free")

ggsave("application_time.png")

# General - Resources
ggplot(resources_data, aes(application_conf, aggregated_cpu_usage)) + 
  geom_boxplot() + 
  geom_point() +
  xlab("Controlador") +
  ylab("Uso de CPU") +
  facet_grid(application ~ actuator, scales = "free")

ggsave("resources.png")

