
## Usage
1. Download the clean version Cassandra using `git clone https://github.com/apache/cassandra.git`, then switch to 3.11 version using `git checkout cassandra-3.11`
2. Download the injected version Cassandra using `git clone https://github.com/functioner/cassandra.git`, then switch to 3.11 version using `git checkout cassandra-3.11`
3. Make three soft links such that src-1 and src-2 point to the clean version while src-3 points to the injected version.  
4. Run `./setup.sh` to finish setup for experiment.
2. Start a Cassandra cluster of 3 nodes by running `./start-cluster.sh 10`, and then run `./check-status.sh` to wait until all nodes startup (see three "Startup complete" in the log
3. Run `create.sh` to create a keyspace and table. The requests are sent to node 1. Run `jps` to check that it is finished. (no CassandraMain process left, may take a bit longer time
4. Run `parallel.sh` to start the parallel readers and writers. Each of them is dedicated to only one node according according to our client design. Then run `jps` to wait all of them being finished. However, there will be always two remaining. They are the reader and writer for node3. Checking the client log file `client-read-3.out` and `client-write-3.out` can realize us that they are failed.
5. Run `./stop-cluster.sh` to stop the ndoes.
