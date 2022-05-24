#!/bin/bash

worker=$1

ready=0
while [ $ready -eq 0 ]
do
  #echo "ssh -o ConnectTimeout=2 ${worker} echo hello"
  response="`ssh ${worker} echo hello`"
  if [ "${response}" = "hello" ]; then
    ready=1
  else
    sleep 1
  fi
done
echo "${worker} is alive"
