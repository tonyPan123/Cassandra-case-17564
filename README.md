
## Usage
1. Run `./download.sh` (Download the original Cassandra and fault injection Cassandra and switch to release 3.11.10).
2. Use `ant jar` to compile src-1 and src-3 (src-2 soft links to src-1). 
3. cd to `datastax-cassandra-client` directory and use `mvn package` to compile the datastax client.
4. Run `./setup.sh` to finish setup for experiment (preparing the conf and scripts, and deleting the old logs and data).
5. Start a Cassandra cluster of 3 nodes by running `./start-cluster.sh`, and then run `./check-status.sh` to wait until all nodes startup (until seeing three "Startup complete" in the log, in about 20 seconds)
6. Run `create.sh` to create a keyspace and table. The requests are sent to node 1. Run `jps` to check that it is finished. (no `datastax_3_1_4-1.0-jar-with-dependencies.jar` process left, may take a bit longer time
7. Run `parallel.sh` to start the parallel readers and writers. Each of them is dedicated to only one node according according to our client design. Then run `jps` to wait all of them being finished. However, there will be always two remaining. They are the reader and writer for node3. Checking the client log file `client-read-3.out` and `client-write-3.out` to know that they failed.
8. Run `./stop-cluster.sh` to stop the nodes.
