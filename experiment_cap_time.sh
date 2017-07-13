#!/bin/bash

REPS=$1
source experiment.cfg

for rep in `seq 1 $REPS`
do
	echo "rep:$rep"

	for cap in $STARTING_CAPS
	do
		echo "cap:$cap"

		for conf in $TREATMENTS
		do
			cp $TREATMENTS_DIR"/client_bigsea.cfg."$conf client_bigsea.cfg
			python client_bigsea.py $MANAGER_IP $MANAGER_PORT $cap

			while [ "`ssh ubuntu@$MANAGER_IP tail -n 1 /home/ubuntu/bigsea-manager/openstack_generic_plugin.log`" != "Finished application execution" ]
			do
				echo > /dev/null	
			done
			
			app_id="`ssh ubuntu@$CONTROLLER_IP tail -n 1 /home/ubuntu/bigsea-scaler/cap.log | awk -F '|' '{print $2}'`"
			echo "$app_id|$conf|$cap" >> app_conf.txt
		done
	done
done
