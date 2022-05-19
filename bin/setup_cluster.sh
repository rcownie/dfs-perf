#!/bin/bash

# This file is run from the master node of the cluster

workers_num=${1}

# Request autoscaling to the desired number of worker instances
echo "${HOME}/autoscale.sh ${workers_num}"
${HOME}/autoscale.sh ${workers_num}

# Make sure the master node itself has all software installed
echo "${HOME}/dfs-perf/bin/setup_node.sh"
${HOME}/dfs-perf/bin/setup_node.sh

# Wait until we have the correct number of workers_num
cur_workers=0
while [ ${cur_workers} -ne ${workers_num} ]
do
  sleep 5
  ips=`${HOME}/list_ips.sh`
  sudo bash -c "echo -e '$ips' > /etc/dsh/machines.list"
  cur_workers="`cat /etc/dsh/machines.list | wc -l`"
  echo "cur_workers=${cur_workers}"
done

# All workers exist, but wait until ssh can connect to them
for worker in `cat /etc/dsh/machines.list`
do
  ready=0
  while [ $ready -eq 0 ]
  do
    echo "ssh ${worker} echo hello"
    response="`ssh ${worker} echo hello`"
    echo "response=${response}"
    if [ "${response}" = "hello" ]; then
      ready=1
    else
      sleep 2
    fi
  done
done

# Initialize all workers in cluster
for worker in `cat /etc/dsh/machines.list`
do
  echo "copy package to ${worker} ..."
  ssh ${worker} cat < ${HOME}/package.tgz ">" package.tgz
done

# Untar the package on all workers
echo "all workers untar package ..."
dsh -a --concurrent-shell --forklimit 32 tar xfz package.tgz

# And run the setup_node.sh on all workers
echo "all workers setup_node.sh ..."
dsh -a --concurrent-shell --forklimit 32 dfs-perf/bin/setup_node.sh

