#!/bin/bash

# This file is run from the master node of the cluster

workers_num=${1}

BIN=${HOME}/dfs-perf/bin

# Request autoscaling to the desired number of worker instances
echo "${HOME}/autoscale.sh ${workers_num}"
${HOME}/autoscale.sh ${workers_num}

# Make sure the master node itself has all software installed
echo -n "Master setup_node.sh   begin at "; date
echo "${BIN}/setup_node.sh"
${BIN}/setup_node.sh
echo -n "Master setup_node.sh   end   at "; date

# Wait until we have the correct number of workers_num
echo -n "Wait for autoscaling   begin at "; date
cur_workers=0
while [ ${cur_workers} -ne ${workers_num} ]
do
  sleep 5
  ips=`${HOME}/list_ips.sh`
  sudo bash -c "echo -e '$ips' > /etc/dsh/machines.list"
  cur_workers="`cat /etc/dsh/machines.list | wc -l`"
  echo "cur_workers=${cur_workers}"
done
echo -n "Wait for autoscaling   end   at "; date

# All workers exist, but wait until ssh can connect to them
echo -n "Connect to all workers begin at "; date
for worker in `cat /etc/dsh/machines.list`
do
  ${BIN}/wait_until_alive.sh ${worker} &
done
wait
echo -n "Connect to all workers end   at "; date

echo -n "Config ssh all workers begin at "; date
tar cf a.tar .ssh/id*
for worker in `cat /etc/dsh/machines.list`
do
  echo "scp a.tar ${worker}:a.tar"
  scp a.tar ${worker}:a.tar &
done
wait
dsh -a --concurrent-shell --forklimit 64 "tar xf a.tar; rm a.tar"
echo -n "Config ssh all workers end   at "; date

# Initialize all workers in cluster
echo -n "Broadcast package.tgz  begin at "; date
${BIN}/broadcast_file.sh ${HOME}/package.tgz ${HOME}/package.tgz
echo -n "Broadcast package.tgz  end   at "; date

# Untar the package on all workers

echo -n "Workers untar package  begin at "; date
dsh -a --concurrent-shell --forklimit 64 tar xfz package.tgz
echo -n "Workers untar package  end   at "; date

# And run the setup_node.sh on all workers
echo -n "Workers setup_node.sh  begin at "; date
dsh -a --concurrent-shell --forklimit 64 dfs-perf/bin/setup_node.sh
echo -n "Workers setup_node.sh  end   at "; date

