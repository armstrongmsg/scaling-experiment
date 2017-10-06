#!/bin/bash

source conf/experiment.cfg

MASTER_IP=$1
# For K-means: 168
TOTAL_TASKS=$2

STARTING_CAP=$STARTING_CAPS
ACTUATOR=$ACTUATORS

python scripts/client/client.py conf $MANAGER_IP $MANAGER_PORT $STARTING_CAP $ACTUATOR > /dev/null

while [ -z `curl -s $MASTER_IP:4040/api/v1/applications | grep id | awk -F'[:,]' '{print $2}'` ]
do 
	sleep 1
done

app_id="`curl -s $MASTER_IP:4040/api/v1/applications | grep id | awk -F'[:,]' '{print $2}' | tr -d '"'`"

sleep 10

success=0
progress=0
start_time=`date +%s`

while [ $success -eq 0 ]
do
	time=$(( `date +%s` - $start_time ))
	echo $progress,$time
	progress="`python scripts/utils/spark_application_progress.py $MASTER_IP $app_id $TOTAL_TASKS 2> /dev/null`"
	success=$?
	sleep 1
done