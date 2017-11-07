#!/bin/bash

function run_spark_application()
{
	#
	# Get instances IDs
	#
	echo "Waiting for application ID"
	
	instances_ids=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".$1[\"instances\"]" | head -n -1 | tail -n+2 | tr -d [\",]`
		
	while [[ -z $instances_ids ]]
	do
		instances_ids=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".$1[\"instances\"]" | head -n -1 | tail -n+2 | tr -d [\",]`
		sleep 1
	done
	
	#
	# Wait for application
	#
	echo "Waiting for application"	

	while [ -z `curl -s $MASTER_IP:4040/api/v1/applications | grep \"id\" | awk -F'[:,]' '{print $2}'` ]
	do 
		sleep 1
	done
	
	app_id=`curl -s $MASTER_IP:4040/api/v1/applications | grep \"id\" | awk -F'[:,]' '{print $2}' | tr -d '"'`
	
	sleep 10
	
	success=0
	progress=0
	start_time=`date +%s`

	total_tasks="`cat treatments/applications/$2.cfg | grep total_tasks | awk {'print $3'}`"

	echo "Collecting progress"
	while [ $success -eq 0 ]
	do
		#
		# Collect application progress
		#
		time=$(( `date +%s` - $start_time ))
		
		echo $progress,$time >> "progress.csv"
		progress="`python scripts/utils/spark_application_progress.py $MASTER_IP $app_id $total_tasks 2> error.log`"
		success=$?
		
		#
		# Collect resources usage for all instances
		#
		for instance_id in $instances_ids
		do
			CPU_DATA_DIR="$EXPERIMENT_CPU_DATA_DIR/profile-$2/$1"
                          
			mkdir -p $CPU_DATA_DIR

			bash scripts/utils/get_cpu_usage.sh $instance_id 2> error_output.txt >> "$CPU_DATA_DIR/$instance_id"".cpu_data" &
		done

		wait

		sleep 1
	done
}

function run_os_generic_application()
{
	APP_ID=$1
	app=$2
	
	#
	# Get instance ID
	#
	instances_ids=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".$APP_ID[\"instances\"]" | head -n -1 | tail -n+2 | tr -d [\",]`
	
	echo "Waiting for instance ID"
	while [[ -z $instances_ids ]]
	do
		instances_ids=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".$APP_ID[\"instances\"]" | head -n -1 | tail -n+2 | tr -d [\",]`
		sleep 1
	done
	
	#
	# Get instance IP
	#
	instance_ip=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".$APP_ID[\"ips\"]" | head -n -1 | tail -n+2 | tr -d [\",]`
	
	echo "Waiting for instance IP"
	while [[ -z $instance_ip ]]
	do
		instance_ip=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".$APP_ID[\"ips\"]" | head -n -1 | tail -n+2 | tr -d [\",]`
		sleep 1
	done

	#
	# Wait until application starts
	#
	echo "Waiting for application"
	while [[ -z $progress ]]
	do
		progress="`ssh -q -o "StrictHostKeyChecking no" -i ~/.ssh/bigsea -l ubuntu $instance_ip tail -n 1 /home/ubuntu/app-progress.log | awk -F'#' {'print $2'}`"
		sleep 1
	done
	
	start_time=`date +%s`
	
	echo "Collecting progress"
	while [[ -n $progress ]]
	do
		#
		# Collect application progress
		#
		time=$(( `date +%s` - $start_time ))
		echo $progress,$time >> "progress.csv"
		progress="`ssh -q -o "StrictHostKeyChecking no" -i ~/.ssh/bigsea -l ubuntu $instance_ip tail -n 1 /home/ubuntu/app-progress.log | awk -F'#' {'print $2'}`"
		sleep 1
		
		#
		# Collect resources usage for all instances
		#
		for instance_id in $instances_ids
		do
			CPU_DATA_DIR="$EXPERIMENT_CPU_DATA_DIR/profile-$app/$APP_ID"
                          
			mkdir -p $CPU_DATA_DIR

			bash scripts/utils/get_cpu_usage.sh $instance_id 2> error_output.txt >> "$CPU_DATA_DIR/$instance_id"".cpu_data" &
		done

		wait
	done
}

source conf/experiment.cfg

STARTING_CAP=$STARTING_CAPS
ACTUATOR=$ACTUATORS
rep=$1

DATE_TIME="`date +%Y-%m-%d_%H-%M-%S`"
EXPERIMENT_CPU_DATA_DIR="results/output/cpu_data_$DATE_TIME"

cp "treatments/scaling/$TREATMENTS" "conf/scaling.cfg"

for rep in `seq 1 $rep`
do
	for app in $APPLICATIONS
	do
		echo "rep:$rep|app:$app"
		echo "-----------------"
		
		touch "progress.csv"		

		if [ $app = "terasort" ]
		then
			cp "treatments/applications/teragen.cfg" "conf/application.cfg"
			APP_ID="`python scripts/client/client.py conf $MANAGER_IP $MANAGER_PORT $STARTING_CAP $ACTUATOR`"
			APP_ID="`echo $APP_ID | tr -d '"'`"
			run_spark_application $APP_ID teragen
			mv progress.csv "$EXPERIMENT_CPU_DATA_DIR/profile-$app/$APP_ID/progress_teragen.csv"
			
			cp "treatments/applications/terasort.cfg" "conf/application.cfg"
			APP_ID="`python scripts/client/client.py conf $MANAGER_IP $MANAGER_PORT $STARTING_CAP $ACTUATOR`"
			APP_ID="`echo $APP_ID | tr -d '"'`"
			run_spark_application $APP_ID terasort
			mv progress.csv "$EXPERIMENT_CPU_DATA_DIR/profile-$app/$APP_ID/progress_terasort.csv"
			
			cp "treatments/applications/teravalidate.cfg" "conf/application.cfg"
			APP_ID="`python scripts/client/client.py conf $MANAGER_IP $MANAGER_PORT $STARTING_CAP $ACTUATOR`"
			APP_ID="`echo $APP_ID | tr -d '"'`"
			run_spark_application $APP_ID teravalidate
			mv progress.csv "$EXPERIMENT_CPU_DATA_DIR/profile-$app/$APP_ID/progress_teravalidate.csv"
		#
		# OS Generic Application
		#
		elif [ $app = "cpu_bound_scripted" -o $app = "io" -o $app = "wordcount" ]
		then
			cp "treatments/applications/$app.cfg" "conf/application.cfg"
		
			APP_ID="`python scripts/client/client.py conf $MANAGER_IP $MANAGER_PORT $STARTING_CAP $ACTUATOR`"
			APP_ID="`echo $APP_ID | tr -d '"'`"
			
			run_os_generic_application $APP_ID $app			
			mv progress.csv "$EXPERIMENT_CPU_DATA_DIR/profile-$app/$APP_ID" 
		#
		# Spark Application
		#
		else
			cp "treatments/applications/$app.cfg" "conf/application.cfg"
		
			APP_ID="`python scripts/client/client.py conf $MANAGER_IP $MANAGER_PORT $STARTING_CAP $ACTUATOR`"
			APP_ID="`echo $APP_ID | tr -d '"'`"
			
			run_spark_application $APP_ID $app
			mv progress.csv "$EXPERIMENT_CPU_DATA_DIR/profile-$app/$APP_ID"
		fi
	done
	
	sleep 10
done

rm host-*
