#!/bin/bash

source conf/experiment.cfg

START_CAP=$1
RESULTS_TO_PROCESS=$2

CAPS_LOG_FILE="cap.log"
APPLICATION_TIME_LOG_FILE="application_time.log"
APPLICATION_CONF_FILE="$RESULTS_TO_PROCESS/app_conf.txt"

applications="`cat $APPLICATION_CONF_FILE | awk -F "|" {'print $1'}`"

for application_id in $applications
do
	application_id="`echo $application_id | tr -d '"'`"
	start_time=`cat $APPLICATION_CONF_FILE | grep "$application_id|" | awk -F '|' '{print $5}'`
	application_time=`cat $APPLICATION_CONF_FILE | grep "$application_id|" | awk -F '|' '{print $4}'`
	application_conf="`cat $APPLICATION_CONF_FILE | grep "$application_id|" | awk -F '|' '{print $2}'`"
	
	resources_usage_dir="$RESULTS_TO_PROCESS/$application_conf/$application_id"
	resources_usage=0

	for instance_id in $INSTANCES_IDS
	do
		resources_usage_filename="$resources_usage_dir"/"$instance_id".cpu_data
		resources_usage_instance=`cat $resources_usage_filename | awk -F ',' 'NR>1{nt=$1-t; nu=$3; sum += nt*u; u=nu} {t=$1; u=$3} END {print sum}'`
		resources_usage=$(( $resources_usage + $resources_usage_instance ))
	done

	echo "$application_id,$resources_usage,$application_time,$application_conf,$START_CAP"
done
