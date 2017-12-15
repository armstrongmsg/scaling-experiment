#!/bin/bash

function run_application()
{
	cp $1 "conf/application.cfg"
	APP_ID="`python scripts/client/client.py conf $MANAGER_IP $MANAGER_PORT $cap $actuator`"
	APP_ID="`echo $APP_ID | tr -d '"'`"
			
	STATUS=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".[\"$APP_ID\"][\"status\"]"`
	instances_ids=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".[\"$APP_ID\"][\"instances\"]" | head -n -1 | tail -n+2 | tr -d [\",]`
	
	while [[ -z $instances_ids ]]
	do
		instances_ids=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".[\"$APP_ID\"][\"instances\"]" | head -n -1 | tail -n+2 | tr -d [\",]`
		sleep 1
	done
	
	while [[ $STATUS != "OK" && ($STATUS != "Error") ]]
	do		
		for instance_id in $instances_ids
		do
			CPU_DATA_DIR="$EXPERIMENT_CPU_DATA_DIR/$conf/$APP_ID"
                          
			mkdir -p $CPU_DATA_DIR

			bash scripts/utils/get_cpu_usage.sh $instance_id 2> error_output.txt >> "$CPU_DATA_DIR/$instance_id"".cpu_data" &
		done

		wait
		
		STATUS=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".[\"$APP_ID\"][\"status\"]"`
	done

	APPLICATION_TIME=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".[\"$APP_ID\"][\"time\"]"`
	APPLICATION_START_TIME=`curl http://$MANAGER_IP:$MANAGER_PORT/manager/status 2> /dev/null | jq -r ".[\"$APP_ID\"][\"start_time\"]"`
}

REPS=$1
source conf/experiment.cfg

DATE_TIME="`date +%Y-%m-%d_%H-%M-%S`"
EXPERIMENT_CPU_DATA_DIR="results/output/cpu_data_$DATE_TIME"

for rep in `seq 1 $REPS`
do
	for actuator in $ACTUATORS
	do
		for app in $APPLICATIONS
		do
			for cap in $STARTING_CAPS
			do
				for conf in $TREATMENTS
				do
					echo "rep:$rep|actuator:$actuator|app:$app|cap:$cap|conf:$conf"			
		
					cp "treatments/scaling/$conf" "conf/scaling.cfg"
					
					if [ $app = "terasort" ]
					then
						TOTAL_APPLICATION_TIME=0		
						
						run_application "treatments/applications/teragen.cfg"
						FINAL_APPLICATION_START_TIME=$APPLICATION_START_TIME
						TOTAL_APPLICATION_TIME=`echo "$TOTAL_APPLICATION_TIME + $APPLICATION_TIME" | bc -l`
				
						run_application "treatments/applications/terasort.cfg"
						TOTAL_APPLICATION_TIME=`echo "$TOTAL_APPLICATION_TIME + $APPLICATION_TIME" | bc -l`
						
						run_application "treatments/applications/teravalidate.cfg"
						TOTAL_APPLICATION_TIME=`echo "$TOTAL_APPLICATION_TIME + $APPLICATION_TIME" | bc -l`
						
						echo "$APP_ID,$conf,$cap,$TOTAL_APPLICATION_TIME,$FINAL_APPLICATION_START_TIME,$actuator" >> app_conf.txt
					else
						run_application "treatments/applications/$app.cfg"
						echo "$APP_ID,$conf,$app,$cap,$APPLICATION_TIME,$APPLICATION_START_TIME,$actuator" >> app_conf.txt
					fi
				done
			done
		done
	done
done

cp app_conf.txt $EXPERIMENT_CPU_DATA_DIR
cp -r treatments/applications treatments/scaling $EXPERIMENT_CPU_DATA_DIR

rm host-*
