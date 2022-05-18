#!/bin/bash

DFS_PERF=/home/ubuntu/dfs-perf
BIN=${DFS_PERF}/bin

if [ -f /etc/dsh/machines.list ]; then
  echo "Copy /etc/dsh/machines.list ..."
  cp /etc/dsh/machines.list ${DFS_PERF}/conf/slaves
fi

export DFS_PERF_SLAVES_NUM=`wc -l ${DFS_PERF}/conf/slaves | cut -d ' ' -f1`

echo "DFS_PERF_SLAVES_NUM=${DFS_PERF_SLAVES_NUM}"

for threads in 1 2 4 8 16 32
do
  export DFS_PERF_THREADS_NUM=${threads}
  for params in \
    files512_size1M \
    files8_size256M \
    files16_size128M \
    files32_size64M \
    files64_size32M \
    files128_size16M
  do
    test="SimpleWrite_${params}"
    echo -n "${test} start at " ; date
    ${BIN}/dfs-perf-clean
    ${BIN}/dfs-perf ${test}
    ${BIN}/dfs-perf-collect ${test}
  done
done
