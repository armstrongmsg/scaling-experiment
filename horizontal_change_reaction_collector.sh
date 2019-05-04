#!/bin/bash

function start_application(){
	kubectl run factorial --image=armstrongmsg/test-scaling:factorial1 --port=5000
	kubectl expose deployment/factorial --type="NodePort" --target-port=5000 --port=8080
	export NODE_PORT=$(kubectl get services/factorial -o go-template='{{(index .spec.ports 0).nodePort}}')

	while [ $? -ne 0 ]
	do
		sleep 1
		curl -s http://$MASTER_IP:$NODE_PORT/run/5000 > $LOG_FILE
	done
}

function stop_application(){
	kubectl delete deployment factorial
	kubectl delete service factorial
}

function start_execution(){
        curl -s -X POST $FACTORIAL_CONTROL_URL/start/$N/$TOTAL_TASKS > $LOG_FILE

        while [ $? -ne 0 ]
        do
                sleep 1
                curl -s -X POST $FACTORIAL_CONTROL_URL/start/$N/$TOTAL_TASKS > $LOG_FILE
        done
}

function stop_execution(){
	curl -s -X POST $FACTORIAL_CONTROL_URL/stop
	
	STOPPED="`curl -s $FACTORIAL_CONTROL_URL/stopped`"

	while [ $STOPPED != "True" ]
	do
		STOPPED="`curl -s $FACTORIAL_CONTROL_URL/stopped`"
		sleep 1
	done
}

function change_replicas(){
        kubectl scale deployments/factorial --replicas=$1
}

# --------------------------------------------------------------

CONF_FILE="conf/tuning.cfg"
FACTORIAL_APPLICATION="scripts/applications/factorial.py"
LOAD_BALANCER="scripts/tuning/factorial_control.py"

source $CONF_FILE

echo "time,tasks,change" > $OUTPUT_FILE

echo "Starting application"
start_application

echo "Starting load control"
python $LOAD_BALANCER $MASTER_IP $NODE_PORT &> $LOG_FILE &
FACTORIAL_CONTROL_PID=$!
FACTORIAL_CONTROL_URL="http://$FACTORIAL_CONTROL_IP:$FACTORIAL_CONTROL_PORT"

for CAP in $CAPS
do
	echo "------------------------------------"
    echo "Running for base:$BASE and cap:$CAP"
    echo "Set cap to base level"
	change_replicas $BASE

	echo "Starting execution"
	start_execution

	echo "Starting performance monitoring"
	START_TIME=`date +%s`
	START_TIME_NANO=`date +%s%N`
	CHANGE_TIME=$(( $START_TIME + $OBSERVED_TIME/2 ))
	END_TIME=$(( $START_TIME + $OBSERVED_TIME ))

	completed_tasks=`curl -s $FACTORIAL_CONTROL_URL/tasks`

	while [ `date +%s` -lt $CHANGE_TIME ]
	do
		completed_tasks=`curl -s $FACTORIAL_CONTROL_URL/tasks`
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
		completed_tasks=`curl -s $FACTORIAL_CONTROL_URL/tasks`
		elapsed_time=$(( `date +%s%N` - $START_TIME_NANO ))
		echo "$elapsed_time,$completed_tasks,$BASE-$CAP" >> "task.csv"
		sleep $WAIT_COLLECT
	done

	echo "Stopping execution"
	stop_execution

    BASE=$CAP
done

echo "--------------------------------------"
echo "Stopping load control"
kill $FACTORIAL_CONTROL_PID &> $LOG_FILE

echo "Stopping application"
stop_application

