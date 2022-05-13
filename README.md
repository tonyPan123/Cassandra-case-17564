
## Usage
1. Run `./download.sh` (Download the original Cassandra and fault injection Cassandra and switch to release 3.11.10).
2. Use `ant jar` to compile src-1 and src-3 (src-2 soft links to src-1). 
3. cd to `datastax-cassandra-client` directory and use `mvn package` to compile the datastax client.
4. Run `./setup.sh` to finish setup for experiment (preparing the conf and scripts, and deleting the old logs and data).
5. Start a Cassandra cluster of 3 nodes by running `./start-cluster.sh`, and then run `./check-status.sh` to wait until all nodes startup (until seeing three "Startup complete" in the log, in about 20 seconds)
6. Run `create.sh` to create a keyspace and table. The requests are sent to node 1. Run `jps` to check that it is finished. (no `datastax_3_1_4-1.0-jar-with-dependencies.jar` process left, may take a bit longer time
7. Run `parallel.sh` to start the parallel readers and writers. Each of them is dedicated to only one node according according to our client design. Then run `jps` to wait all of them being finished. However, there will be always two remaining. They are the reader and writer for node3. Checking the client log file `client-read-3.out` and `client-write-3.out` to know that they failed.
8. Run `./stop-cluster.sh` to stop the nodes.

## Explanation
During startup of Cassandra nodes, the nonPeriodicTask thread has potential to be scheduled many times to tidy the SSTable either by manually calling Flush or automatically compaction. 
Also, nonPeriodicTask has the potential to schedule itself for next SSTable tidy operation. So it is very likely there is delay for the scheduling of SSTable tidy task. Also during SSTable
tidying in nonPeriodicTask thread. There is `Files.delete(file.toPath());` which has potential to throw IOException. During handling it, when the DaemonStartup is not completed, the node
will be killed while it will be tolerated after the startup. Because there is nonsynchronization between the main Thread and nonPeriodicTask thread, so there is likely concurrency issue:
maybe one IOException should cause the kill of the node but there is delay such that it finally can be tolerated. To simulate this, we do the following experiment: at the 3rd node, 
in the `tidy()` function called by CompactionManager, we delay the schedule of them by 1s for five times. Then for the `Files.delete(file.toPath());` that is called by it, we manually 
throw IOException the tenth times this place is trasversed. The experiment results show that the delay cause the Exception thrown handling time to the place when Daemon is already startup.
So this will be tolerated. Then we use client datasax to create the data and do random read/write. Then fianlly we found that the node3(injected) can not perform client read/write operation
while others can. So this means that this node should be killed when that exception is thrown.
