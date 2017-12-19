#!/bin/bash

# requirements
# bc

instance_id=$1
tunnel=$2
compute_nodes="c4-compute11 c4-compute12 c4-compute22"
compute_nodes_ports="10011 10012 10022"
keypath="~/.ssh/bigsea"

function remove_and_convert_tail()
{
        if [[ $1 == *"K"* ]]
        then
                result=$(( `echo $1 | tr -d 'K'` * 1024 ))
        elif [[ $1 == *"M"* ]]
        then
                result=$(( `echo $1 | tr -d 'M'` * 1048576 ))
        else
                result=$1
        fi

        echo $result
}

function get_usage()
{
	instance_id=$1
	
	instance_name="`virsh dominfo $instance_id | grep Name | awk {'print $2'} 2> /dev/null`";
	cap="`virsh schedinfo $instance_name | grep vcpu_quota | awk {'print $3'} 2> /dev/null`";
	
	if [ "$cap" = "-1" ]; then cap="100"; else cap=$(( $cap / 1000 )); fi
	
	compute_node_cpus="`cat /proc/cpuinfo | grep -c processor`";
	instance_cpus="`virsh dominfo $instance_id | grep "CPU(s)" | awk {'print $2'}`";
	virt_top_output="`virt-top -n 2 --init-file virt-top.conf --stream | grep $instance_name`";
	cpu_usage="`echo $virt_top_output | awk '{print $17}' 2> /dev/null`";
	cpu_usage="`echo "$cpu_usage*$compute_node_cpus/$instance_cpus" | bc`";
	
	read_data="`echo $virt_top_output | awk '{print $13}' 2> /dev/null`";
	written_data="`echo $virt_top_output | awk '{print $14}' 2> /dev/null`";

	host_cpu_idle="`sar 1 1 | awk 'FNR==4'{'print $9'}`"
	host_cpu_usage="`echo "100 - $host_cpu_idle" | bc`"

	written_bytes="`remove_and_convert_tail $written_data`"
	read_bytes="`remove_and_convert_tail $read_data`"

	if [ -n $read_bytes -a -n $written_bytes -a -n $cpu_usage  ]
	then
		echo "`date +%s`",$cap,$cpu_usage,$read_bytes,$written_bytes,$host_cpu_usage
	fi
}

if [ -f "host-$instance_id" ]
then
        compute_node="`cat host-$instance_id`"
else
if [ $tunnel == "0" ]
        then
                for compute_node_candidate in $compute_nodes
                do
                        in_host="`ssh root@$compute_node_candidate virsh dominfo $instance_id > /dev/null; echo $?`"

                        if [ $in_host = "0" ]
                        then
                                compute_node=$compute_node_candidate
                                echo $compute_node > "host-$instance_id"
                                break
                        fi
                done
        elif [ $tunnel == "1" ]
        then
                for compute_node_candidate in $compute_nodes_ports
                do
                        in_host="`ssh -i $keypath root@localhost -p $compute_node_candidate virsh dominfo $instance_id > /dev/null; echo $?`"

                        if [ $in_host = "0" ]
                        then
                                compute_node=$compute_node_candidate
                                echo $compute_node > "host-$instance_id"
                                break
                        fi
                done
        else
                echo "Invalid tunnel"
                exit
        fi
fi

if [ $tunnel == "0" ]
then
        ssh root@$compute_node "$(typeset -f); get_usage $instance_id"
elif [ $tunnel == "1" ]
then
        ssh -i $keypath root@localhost -p $compute_node "$(typeset -f); get_usage $instance_id"
else
        echo "Invalid tunnel"
        exit
fi