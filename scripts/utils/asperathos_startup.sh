#!/bin/bash

ASPERATHOS_HOME="$1"

CONTROLLER_HOME="$ASPERATHOS_HOME/asperathos-controller"
MONITOR_HOME="$ASPERATHOS_HOME/asperathos-monitor"
BROKER_HOME="$ASPERATHOS_HOME/asperathos-manager"

echo "Starting controller"

cd $CONTROLLER_HOME
screen -dmS controller ./run.sh >> controller_output.log

while [[ "`ps xau | grep asperathos-controller | grep -v grep | grep -v SCREEN |  wc -l`" -ne 2 ]]
do
	sleep 1
done

echo "Starting monitor"

cd $MONITOR_HOME
screen -dmS monitor ./run.sh >> monitor_output.log

while [[ "`ps xau | grep asperathos-monitor | grep -v grep | grep -v SCREEN |  wc -l`" -ne 2 ]]
do
	sleep 1
done

echo "Starting broker"

cd $BROKER_HOME
screen -dmS broker ./run.sh >> broker_output.log

while [[ "`ps xau | grep asperathos-manager | grep -v grep | grep -v SCREEN |  wc -l`" -ne 2 ]]
do
	sleep 1
done

