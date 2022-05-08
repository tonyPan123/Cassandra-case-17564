#!/usr/bin/env bash

workspace=$(cd "$(dirname "${BASH_SOURCE-$0}")"; pwd)

num=$1

for ((i=1;i<=3;i++)); do
  nohup $workspace/start-server.sh $i $num </dev/null >/dev/null 2>&1 &
done
