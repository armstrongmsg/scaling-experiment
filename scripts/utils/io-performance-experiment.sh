#!/bin/bash

for i in `seq 1 $1`
do
	for size in 1000
	do
		for n_threads in 1
		do
			for block_size in 4 16 64
			do

				./run-io-benchmarks.sh $size $block_size $n_threads $2

			done
		done
	done
	
	sleep 3600
done
