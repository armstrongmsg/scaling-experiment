#!/bin/bash

function start_application(){
	scp factorial.py ubuntu@$VM_IP:/home/ubuntu > $LOG_FILE
	ssh ubuntu@$VM_IP "at now <<< 'python factorial.py'" &> $LOG_FILE

	# Checks if the application is ready
	while [ $? -ne 0 ]
	do
		sleep 1
		curl -s http://$VM_IP:$VM_PORT/run/5000 > $LOG_FILE
	done
}

function stop_application(){
	PID="`ssh ubuntu@$VM_IP "ps xau | grep -v grep | grep factorial.py"`"
	PID="`echo $PID | awk '{print $2}'`"
	ssh ubuntu@$VM_IP "kill $PID"
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

function change_cap(){
	cap_virsh=`echo "($2) * 1000" | bc` 
	virsh schedinfo $1 --set vcpu_quota=$cap_virsh > /dev/null
}

# --------------------------------------------------------------

source "tuning.cfg"

echo "time,tasks,change" > $OUTPUT_FILE

echo "Starting application"
start_application

echo "Starting load control"
python factorial_control.py $VM_IP $VM_PORT &> $LOG_FILE &
FACTORIAL_CONTROL_PID=$!
FACTORIAL_CONTROL_URL="http://$FACTORIAL_CONTROL_IP:$FACTORIAL_CONTROL_PORT"

echo "Starting controller"
python controller.py $PROPORTIONAL_GAIN $DERIVATIVE_GAIN $INTEGRAL_GAIN > /dev/null & 
CONTROLLER_PID=$!
CONTROLLER_URL="http://$CONTROLLER_IP:$CONTROLLER_PORT"

echo "Setting starting cap"
cap=$STARTING_CAP
change_cap $VM_NAME $cap

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
	new_cap=`echo "$cap + 100*($action)" | bc -l`
	new_cap=`echo "$new_cap" | awk -F'.' '{print $1}'`
	
	if [ $new_cap -gt $MAX_CAP ]
	then
		new_cap=$MAX_CAP
	fi

	if [ $new_cap -lt $MIN_CAP ]
	then
		new_cap=$MIN_CAP
	fi

	cap=$new_cap
	change_cap $VM_NAME $cap

	echo "progress:$progress"
	echo "time_progress:$time_progress"
	echo "error:$error"
	echo "action:$action"
	echo "new_cap:$cap"

	sleep 5

	completed_tasks=`curl -s $FACTORIAL_CONTROL_URL/tasks`
done

echo "--------------------------------------"

echo "Stopping controller"
kill $CONTROLLER_PID

echo "Stopping load control"
kill $FACTORIAL_CONTROL_PID &> $LOG_FILE

echo "Stopping application"
stop_application

