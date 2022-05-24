#!/bin/sh

srcFile=$1
dstFilePath=$2
children=""

# Current cluster configuration doesn't allow 
childrenSizeMax=16

BIN=${HOME}/dfs-perf/bin

SCP="scp -o StrictHostKeyChecking=no"
SSH="ssh -o StrictHostKeyChecking=no"

if [ $# -le 2 ]; then
  #
  # Level 0, we read /etc/dsh/machines.list and split it into chunks 
  # of up to 16 machines
  #
  allWorkers="`cat /etc/dsh/machines.list`"  
  for phase in 1 2
  do
    parent=""
    for worker in ${allWorkers} BroadcastFileSentinel
    do
      if [ -z "${parent}" ]; then
        parent=${worker}
        children=""
        childrenSize=0
      elif [ ${worker} != BroadcastFileSentinel ]; then
        children="${children} ${worker}"
        childrenSize=`expr ${childrenSize} + 1`
      fi
      #echo "worker=${worker}"
      #echo "childrenSize=${childrenSize}"
      #echo "childrenSizeMax=${childrenSizeMax}"
      #echo "childrenSize=${childrenSize}"
      #echo "children=${children}"
      #echo "parent=${parent}"
      if [ ${childrenSize} -ge ${childrenSizeMax} ] || [ ${worker} = BroadcastFileSentinel ]; then
        if [ -z "${parent}" ]; then
          echo "do nothing" >/dev/null
        elif [ "${parent}" != BroadcastFileSentinel ]; then
          if [ ${phase} -eq 1 ]; then
            # Copy the file to this parent
            echo "${SCP} ${BIN}/broadcast_file.sh ${parent}:${HOME}/broadcast_file.sh"
            ${SCP} ${BIN}/broadcast_file.sh ${parent}:${HOME}/broadcast_file.sh &
            ${SCP} ${srcFile} ${parent}:${dstFilePath} &
          elif [ ${childrenSize} -gt 0 ]; then
            # Copy the file from this parent to its children
            echo "${SSH} ${parent} \"chmod a+rx broadcast_file.sh; ./broadcast_file.sh ${dstFilePath} ${dstFilePath} ${children}\""
            ${SSH} ${parent} "chmod a+rx broadcast_file.sh; ./broadcast_file.sh ${dstFilePath} ${dstFilePath} ${children}" &
          fi
          parent=""
        fi
      fi
    done
    # phase 1 - wait until all parents have the file
    # phase 2 - wait until all children have the file
    wait
    if [ ${phase} -eq 1 ]; then
      echo "master `hostname` copied file to all parents"
    else
      echo "master `hostname` copied file to all workers"
    fi
  done

else
  #
  # Level 1, we distribute to our children
  #
  argIdx=3
  while [ $argIdx -le $# ]
  do
    # Indirect substitution ought to work here, but it's causing mysterious trouble.
    case ${argIdx} in
    3)
      child=$3
      ;;
    4)
      child=$4
      ;;
    5)
      child=$5
      ;;
    6)
      child=$6
      ;;
    7)
      child=$7
      ;;
    8)
      child=$8
      ;;
    9)
      child=$9
      ;;
    10)
      child=$10
      ;;
    11)
      child=$11
      ;;
    12)
      child=$12
      ;;
    13)
      child=$13
      ;;
    14)
      child=$14
      ;;
    15)
      child=$15
      ;;
    16)
      child=$16
      ;;
    17)
      child=$17
      ;;
    18)
      child=$18
      ;;    
    esac
    children="${children} ${child}"
    argIdx=`expr $argIdx + 1`
  done
  for child in ${children}
  do
    ${SCP} ${dstFilePath} ${child}:${dstFileAbsPath} &
  done
  # wait until all children have the file
  wait
  echo "parent `hostname` copied file to ${children}"
fi
