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
  
  for test in \
SimpleWrite_files008_size0016M \
SimpleWrite_files008_size0064M \
SimpleWrite_files008_size0256M \
SimpleWrite_files008_size1024M \
SimpleWrite_files008_size1024M_z1.50 \
SimpleWrite_files008_size1024M_z2.00 \
SimpleWrite_files008_size1024M_z2.50 \
SimpleWrite_files008_size1024M_z3.00 \
SimpleWrite_files008_size1024M_z4.00 \
SimpleWrite_files008_size4096M \
SimpleWrite_files512_size0001M    
  do
    echo -n "TIME: ${test} begin at " ; date
    ${BIN}/dfs-perf-clean
    ${BIN}/dfs-perf ${test}
    ${BIN}/dfs-perf-collect ${test}
    echo -N "TIME: ${test} end   at " ; date
  done
  
  mv -f ${DFS_PERF}/conf/dfs-perf-env.sh.orig ${DFS_PERF}/conf/dfs-perf-env.sh
done
