#!/bin/bash

DFS_PERF=/home/ubuntu/dfs-perf
BIN=${DFS_PERF}/bin

if [ -f /etc/dsh/machines.list ]; then
  echo "Copy /etc/dsh/machines.list ..."
  cp /etc/dsh/machines.list ${DFS_PERF}/conf/slaves
fi

export DFS_PERF_SLAVES_NUM=`wc -l ${DFS_PERF}/conf/slaves | cut -d ' ' -f1`

echo "DFS_PERF_SLAVES_NUM=${DFS_PERF_SLAVES_NUM}"

for threads in 1 4 8 16 64
do
  # The DFS_PERF_THREADS_NUM is distributed to the slaves by copying
  # the dfs-perf-env.sh script.  This ugly hack edits that script on
  # the fly to the desired value before dfs-perf distributes dfs-perf-env.sh
  
  mv -f ${DFS_PERF}/conf/dfs-perf-env.sh ${DFS_PERF}/conf/dfs-perf-env.sh.orig
  sed s/DFS_PERF_THREADS_NUM_placeholder/${threads}/ \
    < ${DFS_PERF}/conf/dfs-perf-env.sh.orig \
    > ${DFS_PERF}/conf/dfs-perf-env.sh
  
  for params in \
size0008M_files001_z1.33 \
size0032M_files001_z1.33 \
size0128M_files001_z1.33 \
size0512M_files001_z1.33 \
size2048M_files001_z1.33
  do
    echo -n "TIME: ${params} begin at " ; date
    ${BIN}/dfs-perf-clean

    echo -n "TIME: SimpleWrite_${params} begin at " ; date
    ${BIN}/dfs-perf SimpleWrite_${params}
    echo -n "TIME: SimpleWrite_${params} end   at " ; date
    ${BIN}/dfs-perf-collect SimpleWrite_${params}

    # Unmount and re-mount filesystem to get cold-read performance
    dsh -a -c -F 20 "sudo umount /flexfs/base"
    dsh -a -c -F 20 "sudo mount /flexfs/base"

    echo -n "TIME: SimpleRead_${params}_cold begin at " ; date
    ${BIN}/dfs-perf SimpleRead_${params}_cold
    ${BIN}/dfs-perf-collect SimpleRead_${params}_cold  
    
    ${BIN}/dfs-perf-clean

    echo -n "TIME: ${test} end   at " ; date
  done

  mv -f ${DFS_PERF}/conf/dfs-perf-env.sh.orig ${DFS_PERF}/conf/dfs-perf-env.sh
done
