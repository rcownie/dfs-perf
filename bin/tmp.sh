#!/bin/bash

NODELIST=slaves.txt

SLAVES=`sort "$NODELIST"|sed  "s/#.*$//;/^$/d"`
UNIQ_SLAVES=`sort "$NODELIST" | uniq | sed  "s/#.*$//;/^$/d"`

echo $SLAVES >slaves1.txt

echo $UNIQ_SLAVES >uslaves1.txt

s_list=""
for s in ${SLAVES}
do
  s_list="${s_list} $s"
done

echo "s_list=${s_list}"

taskid=0
for slave in $UNIQ_SLAVES; do
  slavenum=0
  for m in $SLAVES; do
    if [ $m = $slave ]; then
      slavenum=`expr $slavenum + 1`
    fi
  done
  lasttaskid=`expr $taskid + $slavenum - 1`
  echo "slave=$slave slavenum=${slavenum} taskid=${taskid} lasttaskid=${lasttaskid}"
  # echo -n "Connect to $slave... "
  #ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -t $slave \
  #  $bin/dfs-perf-start.sh $slave $taskid $lasttaskid $1 2>&1
  sleep 0.02
  taskid=`expr $lasttaskid + 1`
done
