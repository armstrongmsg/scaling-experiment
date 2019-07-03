#!/bin/bash

ASPERATHOS_HOME="$1"

CONTROLLER_HOME="$ASPERATHOS_HOME/asperathos-controller"
MONITOR_HOME="$ASPERATHOS_HOME/asperathos-monitor"
BROKER_HOME="$ASPERATHOS_HOME/asperathos-manager"

echo "Stopping controller"
screen -X -S controller kill

echo "Stopping monitor"
screen -X -S monitor kill

echo "Stopping broker"
screen -X -S broker kill

