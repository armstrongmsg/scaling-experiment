#!/bin/bash

REPS=$1
source conf/experiment.cfg

DATE_TIME="`date +%Y-%m-%d_%H-%M-%S`"
EXPERIMENT_CPU_DATA_DIR="results/output/cpu_data_$DATE_TIME"

for rep in `seq 1 $REPS`
do
	echo "rep:$rep"
	
	for actuator in $ACTUATORS
	do
		echo "actuator:$actuator"
		
		for app in $APPLICATIONS
		do
			echo "app:$app"
		
			for cap in $STARTING_CAPS
			do
				echo "cap:$cap"
		
				for conf in $TREATMENTS
				do
					echo "conf:$conf"			
		
					cp "treatments/scaling/$conf" "conf/scaling.cfg"
					
					#cp "$TREATMENTS_DIR/$conf" "conf/scaling.cfg"
					cp "treatments/applications/$app.cfg" "conf/application.cfg"
					APP_ID="`python scripts/client/client.py conf $MANAGER_IP $MANAGER_PORT $cap $actuator`"
					APP_ID="`echo $APP_ID | tr -d '"'`"
		
					STATUS=`curl --data "" http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".$APP_ID[\"status\"]"`
		
					while [[ $STATUS != "OK" && ($STATUS != "Error") ]]
					do
						for instance_id in $INSTANCES_IDS
						do
							CPU_DATA_DIR="$EXPERIMENT_CPU_DATA_DIR/$conf/$APP_ID"
		                                  
							mkdir -p $CPU_DATA_DIR
		
							bash scripts/utils/get_cpu_usage.sh $instance_id 2> error_output.txt >> "$CPU_DATA_DIR/$instance_id"".cpu_data"
						done
		
						sleep 1
						
						STATUS=`curl --data "" http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".$APP_ID[\"status\"]"`
					done
				
					APPLICATION_TIME=`curl --data "" http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".$APP_ID[\"time\"]"`
					APPLICATION_START_TIME=`curl --data "" http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".$APP_ID[\"start_time\"]"`
			
					echo "$APP_ID|$conf|$cap|$APPLICATION_TIME|$APPLICATION_START_TIME" >> app_conf.txt
				done
			done
		done
	done
done

cp app_conf.txt $EXPERIMENT_CPU_DATA_DIR
cp -r treatments/applications treatments/scaling $EXPERIMENT_CPU_DATA_DIR

rm host-*
