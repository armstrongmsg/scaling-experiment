#!/bin/bash

source "tuning.cfg"

ssh ubuntu@$VM_IP "echo "time,perf,task,change" > "task.log""
scp "test_application.py" ubuntu@$VM_IP:/home/ubuntu

for CAP in $CAPS
do
	echo "Running for base:$BASE and cap:$CAP"
	echo "Set cap to base level"
	virsh schedinfo $VM_NAME --set vcpu_quota="$BASE"000 > /dev/null

	echo "Start app"

	ssh ubuntu@$VM_IP "at now <<< 'python test_application.py $N'"

	echo "Wait"
	sleep $WAIT_TIME

	echo "Change cap"
	virsh schedinfo $VM_NAME --set vcpu_quota="$CAP"000 > /dev/null

	echo "Wait"
	sleep $WAIT_TIME

	echo "Kill application"
	PID="`ssh ubuntu@$VM_IP "ps xau | grep -v grep | grep test_application.py"`"
	PID="`echo $PID | awk '{print $2}'`"

	ssh ubuntu@$VM_IP "kill $PID; wait $PID"
	ssh ubuntu@$VM_IP "sed -e 's/$/,$BASE-$CAP/' -i task.log.tmp"
	ssh ubuntu@$VM_IP "cat task.log.tmp >> task.log"

	BASE=$CAP
done

scp ubuntu@$VM_IP:/home/ubuntu/task.log task.csv
