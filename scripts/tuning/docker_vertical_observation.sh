#!/bin/bash

CAPS="10 20 30 40 50 60 70 80 90 100"
REPS=30

echo "Starting application"
CONTAINER_ID="`docker run -d -p 5000:5000 armstrongmsg/test-scaling:factorial1`"
CONTAINER_IP="`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_ID`"

echo "Container ID: $CONTAINER_ID"
echo "Container IP: $CONTAINER_IP"

TIMEFORMAT=%R

echo -n "" > result.csv

for rep in `seq 1 $REPS`
do
	echo "Rep: $rep"

	for cap in $CAPS
	do
		echo "Cap: $cap"
		echo $(( $cap * 1000 )) | sudo tee /sys/fs/cgroup/cpu/docker/$CONTAINER_ID//cpu.cfs_quota_us > /dev/null
		TIME=$( { time curl http://$CONTAINER_IP:5000/run/100000 &> /dev/null; } 2>&1 )
		TIME="`echo "${TIME/,/.}"`"
		echo $cap,$TIME >> results_cpucap_docker.csv
	done
done

echo "Stopping application"
docker stop $CONTAINER_ID > /dev/null
docker rm $CONTAINER_ID > /dev/null

