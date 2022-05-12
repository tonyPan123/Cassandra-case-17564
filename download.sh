#!/usr/bin/env bash

workspace=$(cd "$(dirname "${BASH_SOURCE-$0}")"; pwd)

pushd $workspace
git clone git@github.com:apache/cassandra.git origin-cassandra
pushd origin-cassandra
git checkout cassandra-3.11.10
popd
git clone git@github.com:functioner/cassandra.git fault-cassandra
pushd fault-cassandra
git checkout cassandra-3.11.10
popd
ln -s origin-cassandra src-1
ln -s origin-cassandra src-2
ln -s fault-cassandra src-3
popd $workspace
