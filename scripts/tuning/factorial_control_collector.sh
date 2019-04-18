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
	virsh schedinfo $1 --set vcpu_quota="$2"000 > /dev/null
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

for CAP in $CAPS
do
	echo "------------------------------------"
        echo "Running for base:$BASE and cap:$CAP"
        echo "Set cap to base level"
	change_cap $VM_NAME $BASE

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
		sleep 0.2
	done

        echo "Change cap"
	change_cap $VM_NAME $CAP

	echo "$elapsed_time,$BASE-$CAP" >> "change.csv"

	echo "Resuming performance monitoring"
	while [ `date +%s` -lt $END_TIME ]
	do
		completed_tasks=`curl -s $FACTORIAL_CONTROL_URL/tasks`
		elapsed_time=$(( `date +%s%N` - $START_TIME_NANO ))
		echo "$elapsed_time,$completed_tasks,$BASE-$CAP" >> "task.csv"
		sleep 0.2
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

