#!/bin/bash

# This file is run from the master node of the cluster

workers_num=${1}

# Request autoscaling to the desired number of worker instances
${HOME}/autoscale.sh ${workers_num}

# Make sure the master node itself has all software installed
${HOME}/dfs-perf/bin/setup_node.sh

# Wait until we have the correct number of workers_num
cur_workers=0
while [ ${cur_workers} -ne ${workers_num} ]
do
  sleep 5
  ips=`${HOME}/list_ips.sh`
  sudo bash -c "echo -e '$ips' > /etc/dsh/machines.list"
  cur_workers="`cat /etc/dsh/machines.list | wc -l`"
done

# All workers exist, but we may need to wait a little longer
sleep 20

# Initialize all workers in cluster
for worker in `cat /etc/dsh/machines.list`
do
  ssh ${worker} cat < ${HOME}/package.tgz ">" package.tgz
done

# Untar the package on all workers
dsh -a --concurrent-shell --forklimit 32 tar xfz package.tgz

# And run the setup_node.sh on all workers
dsh -a --concurrent-shell --forklimit 32 tar xfz dfs-perf/bin/setup_node.sh

