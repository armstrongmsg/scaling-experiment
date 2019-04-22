#!/bin/bash

function start_execution(){
        curl -s -X POST $FACTORIAL_CONTROL_URL/start_dist/$WORKLOAD > $LOG_FILE

        while [ $? -ne 0 ]
        do
                sleep 1
                curl -s -X POST $FACTORIAL_CONTROL_URL/start_dist/$WORKLOAD > $LOG_FILE
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

function reset_controller(){
	curl -s -X POST $CONTROLLER_URL/reset
}

function change_replicas(){
	kubectl scale deployments/factorial --replicas=$1
}

# minikube start --vm-driver=kvm2
# kubectl run factorial --image=armstrongmsg/test-scaling:factorial1 --port=5000
# kubectl expose deployment/factorial --type="NodePort" --target-port=5000 --port=8080
# export NODE_PORT=$(kubectl get services/factorial -o go-template='{{(index .spec.ports 0).nodePort}}')
# curl $(minikube ip):$NODE_PORT/run/5000

CONF_FILE="conf/tuning.cfg"
FACTORIAL_APPLICATION="scripts/applications/factorial.py"
CONTROLLER="scripts/utils/controller.py"
LOAD_BALANCER="scripts/tuning/factorial_control.py"

source "$CONF_FILE"

echo "time,tasks,change" > $OUTPUT_FILE

echo "Starting load control"
VM_IP="`minikube ip`"
VM_PORT="`kubectl get services/factorial -o go-template='{{(index .spec.ports 0).nodePort}}'`"
python $LOAD_BALANCER $VM_IP $VM_PORT &> $LOG_FILE &
FACTORIAL_CONTROL_PID=$!
FACTORIAL_CONTROL_URL="http://$FACTORIAL_CONTROL_IP:$FACTORIAL_CONTROL_PORT"

echo "Starting controller"
python $CONTROLLER $PROPORTIONAL_GAIN $DERIVATIVE_GAIN $INTEGRAL_GAIN > /dev/null & 
CONTROLLER_PID=$!
CONTROLLER_URL="http://$CONTROLLER_IP:$CONTROLLER_PORT"

for rep in `seq 1 $REPS`
do
	echo "Creating starting replicas"
	replicas=$STARTING_CAP
	change_replicas $replicas
	
	echo "Starting execution"
	start_execution
	START_TIME=`date +%s%n`
	
	completed_tasks=`curl -s $FACTORIAL_CONTROL_URL/tasks`
	
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
	
		new_replicas=`echo "$replicas + $action" | bc`
	
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
	
		completed_tasks=`curl -s $FACTORIAL_CONTROL_URL/tasks`
	done
	
	echo "$rep,$elapsed_time" >> $TIME_LOG_FILE

	echo "Reset controller"
	reset_controller
	
	echo "--------------------------------------"
done

echo "Stopping controller"
kill $CONTROLLER_PID

echo "Stopping load control"
kill $FACTORIAL_CONTROL_PID &> $LOG_FILE

