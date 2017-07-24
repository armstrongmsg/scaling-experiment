#!/bin/bash

instance_id=$1
compute_nodes="c4-compute11 c4-compute12 c4-compute22"

for compute_node in $compute_nodes
do
	in_host="`ssh root@$compute_node virsh dominfo $instance_id > /dev/null; echo $?`"

	if [ $in_host = "0" ]
	then
		instance_name="`ssh root@$compute_node virsh dominfo $instance_id | grep Name | awk {'print $2'} 2> /dev/null`"
		cap="`ssh root@$compute_node virsh schedinfo $instance_name | grep vcpu_quota | awk {'print $3'} 2> /dev/null`"

		if [ "$cap" = "-1" ]
		then
			cap="100"
		else
			cap=$(( $cap / 1000 ))
		fi

		compute_node_cpus="`ssh root@$compute_node cat /proc/cpuinfo | grep -c processor`"
		instance_cpus="`ssh root@$compute_node virsh dominfo $instance_id | grep "CPU(s)" | awk {'print $2'}`"
		cpu_usage="`ssh root@$compute_node virt-top -n 2 --init-file virt-top.conf --stream | grep $instance_name | awk 'FNR == 2 {print $7}' 2> /dev/null`"
		cpu_usage="`echo "$cpu_usage*$compute_node_cpus/$instance_cpus" | bc`"

		echo "`date +%s`",$cap,$cpu_usage
		break
	fi
done
