#!/bin/bash

source conf/experiment.cfg

CAPS_LOG_FILE="cap.log"
APPLICATION_CONF_FILE="$1"
DATA_DIR="$2"
START_CAP=$3

applications="`cat $APPLICATION_CONF_FILE | awk -F "|" {'print $1'}`"

for application_id in $applications
do
        application_id="`echo $application_id | tr -d '"'`"
        start_time=`cat $APPLICATION_CONF_FILE | grep "$application_id|" | awk -F '|' '{print $5}'`
        application_time=`cat $APPLICATION_CONF_FILE | grep "$application_id|" | awk -F '|' '{print $4}'`
        application_conf="`cat $APPLICATION_CONF_FILE | grep "$application_id|" | awk -F '|' '{print $2}'`"

        resources_usage_dir="$DATA_DIR/$application_conf/$application_id"

        for instance_id in $INSTANCES_IDS
        do
			resources_usage_filename="$resources_usage_dir"/"$instance_id".cpu_data
			resources_usage="`cat $resources_usage_filename`"

			for line in $resources_usage
			do
				timestamp=`echo $line | awk -F ',' '{print $1}'`
				adjusted_timestamp=$(( $timestamp - $start_time ))
				cap=`echo $line | awk -F ',' '{print $2}'`
				cpu_usage=`echo $line | awk -F ',' '{print $3}'`
				host_cpu_usage=`echo $line | awk -F ',' '{print $6}'`
				echo $adjusted_timestamp,$cap,$cpu_usage,$host_cpu_usage,$application_time,$instance_id,$application_id,$application_conf
			done

        done
done
