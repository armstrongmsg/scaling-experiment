#!/bin/bash

function start_application(){
	python $REDIS_CLIENT start $MASTER_IP 31851 $KUBE_CONFIG_FILE $INPUT_FILE &>> $LOG_FILE
	REDIS_PORT=$(kubectl get services/redis-app -o go-template='{{(index .spec.ports 0).nodePort}}')
}

function stop_application(){
	python $REDIS_CLIENT stop $MASTER_IP $REDIS_PORT $KUBE_CONFIG_FILE $INPUT_FILE 2>> $LOG_FILE
}

function start_execution(){
	python $REDIS_CLIENT data $MASTER_IP $REDIS_PORT $KUBE_CONFIG_FILE $INPUT_FILE 2>> $LOG_FILE

	kubectl run factorial --env="REDIS_HOST=redis-app" --command=true /factorial/run.py \
			--image=armstrongmsg/test-scaling:factorial_batch --replicas=$1 --port=5000 2>> $LOG_FILE
}

function stop_execution(){
	kubectl delete deployment factorial
}

function change_replicas(){
 	kubectl scale deployments/factorial --replicas=$1
}

function reset_controller(){
	curl -s -X POST $CONTROLLER_URL/reset
}

function get_completed_tasks() {
	len_queue="`python $REDIS_CLIENT len $MASTER_IP $REDIS_PORT $KUBE_CONFIG_FILE $INPUT_FILE 2> $LOG_FILE`"
	echo $(( $TOTAL_TASKS - $len_queue )) 
}

# --------------------------------------------------------------

REDIS_CLIENT="scripts/utils/redis_client.py"
CONF_FILE="conf/tuning.cfg"
FACTORIAL_APPLICATION="scripts/applications/factorial.py"
CONTROLLER="scripts/utils/controller.py"

source "$CONF_FILE"

echo "time,tasks,change" > $OUTPUT_FILE

echo "Starting controller"
python $CONTROLLER $PROPORTIONAL_GAIN $DERIVATIVE_GAIN $INTEGRAL_GAIN > /dev/null & 
CONTROLLER_PID=$!
CONTROLLER_URL="http://$CONTROLLER_IP:$CONTROLLER_PORT"

for rep in `seq 1 $REPS`
do
	echo "Starting application"
	start_application
	
	echo "Starting execution"
	start_execution $STARTING_CAP
	
	replicas=$STARTING_CAP
	START_TIME=`date +%s%n`
	completed_tasks=`get_completed_tasks`
	
	while [ $completed_tasks -lt $TOTAL_TASKS ]
	do
		echo "--------------------------------------"
		progress=`echo "$completed_tasks / $TOTAL_TASKS" | bc -l` 
	
		current_time=`date +%s%n`
		elapsed_time=`echo "$current_time - $START_TIME" | bc -l`
		time_progress=`echo "$elapsed_time / $EXPECTED_TIME" | bc -l`
	
		error=`echo "$progress - $time_progress" | bc -l`
	
		action=`curl -s $CONTROLLER_URL/action/$error`
		action=`echo "(100*$action)/1" | bc`
		new_replicas=`echo "$replicas + ($action)" | bc`
		
		if [ $new_replicas -gt $MAX_CAP ]
		then
			new_replicas=$MAX_CAP
		fi
	
		if [ $new_replicas -lt $MIN_CAP ]
		then
			new_replicas=$MIN_CAP
		fi
	
		replicas=$new_replicas
		change_replicas $replicas
	
		echo "progress:$progress"
		echo "time_progress:$time_progress"
		echo "error:$error"
		echo "action:$action"
		echo "replicas:$replicas"
	
		echo "$rep,$elapsed_time,$replicas" >> $CAP_LOG_FILE 
		
		sleep 5
	
		completed_tasks=`get_completed_tasks`
	done
	
	echo "$rep,$elapsed_time" >> $TIME_LOG_FILE

	stop_execution
	stop_application

	echo "Reset controller"
	reset_controller

	sleep 20
	
	echo "--------------------------------------"
done

echo "Stopping controller"
kill $CONTROLLER_PID
