#!/bin/bash

DFS_PERF=/home/ubuntu/dfs-perf
BIN=${DFS_PERF}/bin

if [ -f /etc/dsh/machines.list ]; then
  echo "Copy /etc/dsh/machines.list ..."
  cp /etc/dsh/machines.list ${DFS_PERF}/conf/slaves
fi

export DFS_PERF_SLAVES_NUM=`wc -l ${DFS_PERF}/conf/slaves | cut -d ' ' -f1`

echo "DFS_PERF_SLAVES_NUM=${DFS_PERF_SLAVES_NUM}"

for threads in 01 04 08 16 64
do
  # The DFS_PERF_THREADS_NUM is distributed to the slaves by copying
  # the dfs-perf-env.sh script.  This ugly hack edits that script on
  # the fly to the desired value before dfs-perf distributes dfs-perf-env.sh
  
  mv -f ${DFS_PERF}/conf/dfs-perf-env.sh ${DFS_PERF}/conf/dfs-perf-env.sh.orig
  sed s/DFS_PERF_THREADS_NUM=[0-9]*/DFS_PERF_THREADS_NUM=${threads}/ \
    < ${DFS_PERF}/conf/dfs-perf-env.sh.orig \
    > ${DFS_PERF}/conf/dfs-perf-env.sh
  
  for params in \
size0001M_files512 \
size0016M_files008 \
size0064M_files008 \
size0256M_files008 \
size1024M_files008 \
size4096M_files008 \
size1024M_files008_z1.50 \
size1024M_files008_z2.00 \
size1024M_files008_z2.50 \
size1024M_files008_z3.00 \
size1024M_files008_z4.00
  do
    echo -n "TIME: ${test} begin at " ; date
    ${BIN}/dfs-perf-clean

    echo -n "TIME: SimpleWrite_${test} begin at " ; date
    ${BIN}/dfs-perf SimpleWrite_${test}
    ${BIN}/dfs-perf-collect SimpleWrite_${test}

    echo -n "TIME: SimpleRead_${test} begin at " ; date
    ${BIN}/dfs-perf SimpleRead_${test}
    ${BIN}/dfs-perf-collect SimpleRead_${test}

    echo -n "TIME: umount/mount begin at " ; date
    # Unmount and re-mount filesystem to get cold-read performance
    dsh -a "sudo umount /flexfs/base"
    dsh -a "sudo mount /flexfs/base"

    echo -n "TIME: SimpleRead_${test}_cold begin at " ; date
    ${BIN}/dfs-perf SimpleRead_${test}_cold
    ${BIN}/dfs-perf-collect SimpleRead_${test}_cold  

    echo -n "TIME: ${test} end   at " ; date
  done
  
  mv -f ${DFS_PERF}/conf/dfs-perf-env.sh.orig ${DFS_PERF}/conf/dfs-perf-env.sh
done
