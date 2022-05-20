#!/usr/bin/env bash

# This will be auto-edited to substitute the desired value
export DFS_PERF_MASTER_HOSTNAME=172.30.0.194

# This will be auto-edited to substitute the desired value
export DFS_PERF_THREADS_NUM=DFS_PERF_THREADS_NUM_placeholder

# Default value for DFS_PERF_THREADS_NUM
if [ ${DFS_PERF_THREADS_NUM} = "DFS_PERF_THREADS_NUM_placeholder" ]; then
  export DFS_PERF_THREADS_NUM=1
fi

# The number of workers is the line count of conf/slaves
workers_num=`cat ${DFS_PERF_HOME}/conf/slaves | wc -l`

# Pad to 3 digits with leading zero's
if [ ${workers_num} -lt 10 ]; then
  workers_num="00${workers_num}"
elif [ ${workers_num} -lt 100 ]; then
  workers_num="0${workers_num}"
fi

# Pad to 2 digits with a leading zero
threads_num=${DFS_PERF_THREADS_NUM}
for padded in 01 02 03 04 05 06 07 08 09
do
  if [ ${threads_num} -eq ${padded} ]; then
    threads_num=${padded}
  fi
done

if [ -z "${DFS_PERF_WORKSPACE}" ]; then
  # Choose the directory for the benchmark files
  export DFS_PERF_WORKSPACE="/flexfs/base/workspace"
fi

# Choose the master node IP address
DFS_PERF_MASTER_PORT=23333

# The report output path

export DFS_PERF_OUT_DIR="$DFS_PERF_HOME/result_w${workers_num}_t${threads_num}"

# The following gives an example:

if [[ `uname -a` == Darwin* ]]; then
  # Assuming Mac OS X
  export JAVA_HOME=${JAVA_HOME:-$(/usr/libexec/java_home)}
  export DFS_PERF_JAVA_OPTS="-Djava.security.krb5.realm= -Djava.security.krb5.kdc="
else
  # Assuming Linux
  if [ -z "$JAVA_HOME" ]; then
    if [ -d "/usr/lib/jvm/java" ]; then
      export JAVA_HOME=/usr/lib/jvm/java
    else
      export JAVA_HOME=/usr/lib/jvm/default-java
    fi
  fi
fi

export JAVA="$JAVA_HOME/bin/java"

export DFS_PERF_DFS_ADDRESS="file://";

#the slave is considered to be failed if not register in this time
DFS_PERF_UNREGISTER_TIMEOUT_MS=10000

#if true, the DfsPerfSupervision will print the names of those running and remaining nodes
DFS_PERF_STATUS_DEBUG="false"

#if true, the test will abort when the number of failed nodes more than the threshold
DFS_PERF_FAILED_ABORT="true"
DFS_PERF_FAILED_PERCENTAGE=1

CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export DFS_PERF_JAVA_OPTS+="
  -Dlog4j.configuration=file:$CONF_DIR/log4j.properties
  -Dpasalab.dfs.perf.failed.abort=$DFS_PERF_FAILED_ABORT
  -Dpasalab.dfs.perf.failed.percentage=$DFS_PERF_FAILED_PERCENTAGE
  -Dpasalab.dfs.perf.status.debug=$DFS_PERF_STATUS_DEBUG
  -Dpasalab.dfs.perf.master.hostname=$DFS_PERF_MASTER_HOSTNAME
  -Dpasalab.dfs.perf.master.port=$DFS_PERF_MASTER_PORT
  -Dpasalab.dfs.perf.dfs.address=$DFS_PERF_DFS_ADDRESS
  -Dpasalab.dfs.perf.dfs.dir=$DFS_PERF_WORKSPACE
  -Dpasalab.dfs.perf.out.dir=$DFS_PERF_OUT_DIR
  -Dpasalab.dfs.perf.threads.num=$DFS_PERF_THREADS_NUM
  -Dpasalab.dfs.perf.unregister.timeout.ms=$DFS_PERF_UNREGISTER_TIMEOUT_MS
"

#Configurations for file systems
export DFS_PERF_DFS_OPTS="
  -Dpasalab.dfs.perf.hdfs.impl=org.apache.hadoop.hdfs.DistributedFileSystem
  -Dalluxio.user.master.client.timeout.ms=600000
  -Dpasalab.dfs.glusterfs.impl=org.apache.hadoop.fs.glusterfs.GlusterFileSystem
  -Dpasalab.dfs.perf.glusterfs.volumes=glusterfs_vol
  -Dpasalab.dfs.perf.glusterfs.mounts=/vol
"

export DFS_PERF_JAVA_OPTS+=$DFS_PERF_DFS_OPTS