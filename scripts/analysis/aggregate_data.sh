#!/bin/bash

source conf/experiment.cfg

APPLICATION_CONF_FILE="$1"
DATA_DIR="$2"
START_CAP=$3

applications="`cat $APPLICATION_CONF_FILE | awk -F "," {'print $1'}`"

aggregated_data_dir="$DATA_DIR/aggregate"
resources_usage_output_file="$aggregated_data_dir/resources.csv"
aggregated_data_output_file="$aggregated_data_dir/aggregated.csv"

mkdir $aggregated_data_dir
touch $resources_usage_output_file
touch $aggregated_data_output_file

echo "timestamp,cap,cpu_usage,read_bytes,written_bytes,host_cpu_usage,application_time,instance_id,application_id,application_conf,application,actuator" >> $aggregated_data_output_file
echo "application_id,cap,application_time,aggregated_cpu_usage,application_conf,application,actuator" >> $resources_usage_output_file

for application_id in $applications
do
        application_id="`echo $application_id | tr -d '"'`"
        start_time=`cat $APPLICATION_CONF_FILE | grep "$application_id," | awk -F ',' '{print $6}'`
        application_time=`cat $APPLICATION_CONF_FILE | grep "$application_id," | awk -F ',' '{print $5}'`
        application_conf="`cat $APPLICATION_CONF_FILE | grep "$application_id," | awk -F ',' '{print $2}'`"
		application="`cat $APPLICATION_CONF_FILE | grep "$application_id," | awk -F ',' '{print $3}'`"
		actuator="`cat $APPLICATION_CONF_FILE | grep "$application_id," | awk -F ',' '{print $7}'`"

        resources_usage_dir="$DATA_DIR/$application_conf/$application_id"
		aggregated_resources_usage=0
		last_timestamp=$start_time

		for file in `ls $resources_usage_dir`
        do
    		instance_id="`echo $file | awk -F '.' {'print $1'}`"
			resources_usage_filename="$resources_usage_dir"/"$file"
			resources_usage="`cat $resources_usage_filename`"

			for line in $resources_usage
			do
				timestamp=`echo $line | awk -F ',' '{print $1}'`
				adjusted_timestamp=`echo "$timestamp - $start_time" | bc -l`
				cap=`echo $line | awk -F ',' '{print $2}'`
				cpu_usage=`echo $line | awk -F ',' '{print $3}'`
				read_bytes=`echo $line | awk -F ',' '{print $4}'`
				written_bytes=`echo $line | awk -F ',' '{print $5}'`
				host_cpu_usage=`echo $line | awk -F ',' '{print $6}'`
				echo $adjusted_timestamp,$cap,$cpu_usage,$read_bytes,$written_bytes,$host_cpu_usage,$application_time,$instance_id,$application_id,$application_conf,$application,$actuator >> $aggregated_data_output_file 
				
				aggregated_resources_usage=`echo "$aggregated_resources_usage + $cpu_usage*($timestamp - $last_timestamp)" | bc -l`
				last_timestamp=$timestamp
			done	
        done
        
		echo $application_id,$cap,$application_time,$aggregated_resources_usage,$application_conf,$application,$actuator >> $resources_usage_output_file
done
