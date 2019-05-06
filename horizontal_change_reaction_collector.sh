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

function get_completed_tasks() {
	len_queue="`python $REDIS_CLIENT len $MASTER_IP $REDIS_PORT $KUBE_CONFIG_FILE $INPUT_FILE 2> $LOG_FILE`"
	echo $(( $TOTAL_TASKS - $len_queue )) 
}

# --------------------------------------------------------------

REDIS_CLIENT="scripts/utils/redis_client.py"
CONF_FILE="conf/tuning.cfg"
FACTORIAL_APPLICATION="scripts/applications/factorial.py"
LOAD_BALANCER="scripts/tuning/factorial_control.py"

source $CONF_FILE

echo "time,tasks,change" > $OUTPUT_FILE

for CAP in $CAPS
do
	echo "Starting application"
	start_application

	echo "------------------------------------"
    echo "Running for base:$BASE and cap:$CAP"
    echo "Set cap to base level"

	echo "Starting execution"
	start_execution $BASE

	echo "Starting performance monitoring"
	START_TIME=`date +%s`
	START_TIME_NANO=`date +%s%N`
	CHANGE_TIME=$(( $START_TIME + $OBSERVED_TIME/2 ))
	END_TIME=$(( $START_TIME + $OBSERVED_TIME ))

	while [ `date +%s` -lt $CHANGE_TIME ]
	do
		completed_tasks=`get_completed_tasks`
		elapsed_time=$(( `date +%s%N` - $START_TIME_NANO ))
		echo "$elapsed_time,$completed_tasks,$BASE-$CAP" >> "task.csv"
		sleep $WAIT_COLLECT
	done

    echo "Change replicas number"
	change_replicas $CAP

	echo "$elapsed_time,$BASE-$CAP" >> "change.csv"

	echo "Resuming performance monitoring"
	while [ `date +%s` -lt $END_TIME ]
	do
		completed_tasks=`get_completed_tasks`
		elapsed_time=$(( `date +%s%N` - $START_TIME_NANO ))
		echo "$elapsed_time,$completed_tasks,$BASE-$CAP" >> "task.csv"
		sleep $WAIT_COLLECT
	done

	echo "Stopping execution"
	stop_execution
	
	echo "Stopping application"
	stop_application
	
    BASE=$CAP
    
    sleep 20
done



