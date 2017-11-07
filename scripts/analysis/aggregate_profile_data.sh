#!/bin/bash

RESULTS_DIRECTORY="$1"

echo "progress,time,application,application_id" >> "$RESULTS_DIRECTORY/progress_profile_aggregated.csv"
echo "timestamp,cap,cpu_usage,read_bytes,written_bytes,host_cpu_usage,application,application_id" >> "$RESULTS_DIRECTORY/resources_profile_aggregated.csv"

for directory in `ls -d $RESULTS_DIRECTORY/*/`
do
	app=`basename $directory | awk -F '-' {'print $2'}`

	for app_id in `ls $RESULTS_DIRECTORY/profile-$app`
	do
		progress_file="$RESULTS_DIRECTORY/profile-$app/$app_id/progress.csv"
		progress="`cat $progress_file`"
		
		for line in $progress
		do
			echo $line,$app,$app_id >> "$RESULTS_DIRECTORY/progress_profile_aggregated.csv"
		done

		for resources_file in `ls $RESULTS_DIRECTORY/profile-$app/$app_id/*.cpu_data`
		do
			resources="`cat $resources_file`"
			first_timestamp=`head -n 1 $resources_file | awk -F ',' {'print $1'}`
			
			for line in $resources
			do
				timestamp=`echo $line | awk -F ',' '{print $1}'`
				adjusted_timestamp=`echo "$timestamp - $first_timestamp" | bc -l`
				cap=`echo $line | awk -F ',' '{print $2}'`
				cpu_usage=`echo $line | awk -F ',' '{print $3}'`
				read_bytes=`echo $line | awk -F ',' '{print $4}'`
				written_bytes=`echo $line | awk -F ',' '{print $5}'`
				host_cpu_usage=`echo $line | awk -F ',' '{print $6}'`
				echo $adjusted_timestamp,$cap,$cpu_usage,$read_bytes,$written_bytes,$host_cpu_usage,$app,$app_id >> "$RESULTS_DIRECTORY/resources_profile_aggregated.csv"
			done
		done
	done
done