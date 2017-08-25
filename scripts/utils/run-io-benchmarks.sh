#!/bin/bash

size=$1
block_size=$2
n_threads=$3
instance_ip=$4
fsync_freq=1


#
# fio
#

fio_size=`echo "$size/$n_threads" | bc`
fio_output="`ssh ubuntu@$instance_ip fio --name=randwrite --ioengine=libaio --rw=write --bs="$block_size""K" --size="$fio_size""M" --numjobs=$n_threads`"

throughput_fio="`echo "$fio_output" | grep WRITE | awk -F ',' {'print $2'} | awk -F '=' {'print $2'} | awk -F 'KB/s' {'print $1'}`"
iops_fio="`echo "$fio_output" | grep "iops" | awk -F'[=,]' {'print $6'}`"

sleep 2

#
# sysbench
#

ssh ubuntu@$instance_ip sysbench --test=fileio --file-total-size=$size --file-num=1 prepare > /dev/null

sysbench_output="`ssh ubuntu@$instance_ip sysbench --test=fileio --file-total-size="$size""M" --file-block-size="$block_size""K" --file-test-mode=seqwr --file-fsync-freq=$fsync_freq --num-threads=$n_threads run`"

throughput_sysbench="`echo "$sysbench_output" | grep "Total transferred" | awk {'print $8'} |  awk -F"[()]" {'print $2'} | awk -F "Mb/sec" {'print $1'}`"
throughput_sysbench=`echo "$throughput_sysbench*1000/8.0" | bc`

iops_sysbench="`echo "$sysbench_output" | grep Requests | awk {'print $1'}`"

sleep 2

#
# dd
#

count=`echo "$size*1000/$block_size" | bc -l | awk -F'.' {'print $1'}`
throughput_dd=`ssh ubuntu@$instance_ip dd if="/dev/zero" of="ddfile" bs="$block_size""K" count=$count oflag=direct 2> >(awk 'FNR == 3 {print $8}')`
throughput_dd=`echo "$throughput_dd*1000" | bc -l`

sleep 2

#
# cleanup
#

ssh ubuntu@$instance_ip rm test_file.* randwrite* ddfile

#
# results
#

echo "fio",$throughput_fio,$iops_fio,$size,$block_size,$n_threads,"`date +%s`"
echo "dd",$throughput_dd,0,$size,$block_size,$n_threads,"`date +%s`"
echo "sys",$throughput_sysbench,$iops_sysbench,$size,$block_size,$n_threads,"`date +%s`"


sleep 2
