#!/bin/bash

CAPS_LOG_FILE="cap.log"
APPLICATION_TIME_LOG_FILE="application_time.log"
APPLICATION_CONF_FILE="app_conf.txt"
START_CAP=$1


applications="`cat $APPLICATION_CONF_FILE | awk -F "|" {'print $1'}`"

for application_id in $applications
do
	start_time=`cat $APPLICATION_TIME_LOG_FILE | grep $application_id | awk -F '|' '{print $2}'`
	application_time=`cat $APPLICATION_TIME_LOG_FILE | grep $application_id | awk -F '|' '{print $3}'`
	end_time=$(( $start_time + $application_time ))

	application_conf="`cat $APPLICATION_CONF_FILE | grep $application_id | awk -F '|' '{print $2}'`"

	data=`cat cap.log | grep $application_id`
	data="$start_time|$application_id|$START_CAP $data $end_time|$application_id|0"

	for line in $data
	do
		echo $line >> test.txt
	done

	resources_usage=`cat test.txt | awk -F '|' 'NR>1{np=$1-p; nc=$3; sum += np*c; c=nc} {p=$1; c=$3} END {print sum}'`

	echo "$application_id,$resources_usage,$application_time,$application_conf,$START_CAP"

	rm test.txt
done
