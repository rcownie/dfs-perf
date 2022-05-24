#!/bin/bash

sudo umount /flexfs/base
while [ ! -z "`df /flexfs/base | fgrep benchmark`" ]
do
  sleep 2
  sudo umount /flexfs/base
done

sudo mount /flexfs/base
while [ -z "`df /flexfs/base | fgrep benchmark`" ]
do
  sleep 2
  sudo mount /flexfs/base
done

