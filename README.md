
## Usage
1. Run `./download.sh` (Download the original Cassandra and fault injection Cassandra and switch to release 3.11.10).
2. Use `ant jar` to compile src-1 and src-3 (src-2 soft links to src-1). 
3. cd to `datastax-cassandra-client` directory and use `mvn package` to compile the datastax client.
4. Run `./setup.sh` to finish setup for experiment (preparing the conf and scripts, and deleting the old logs and data).
5. Start a Cassandra cluster of 3 nodes by running `./start-cluster.sh`, and then run `./check-status.sh` to wait until all nodes startup (until seeing three "Startup complete" in the log, in about 20 seconds). Note that the cluster starts with empty initial data. And the configuration is generally the default (exception some ports and file locations).
6. Run `create.sh` to create a keyspace and table. The requests are sent to node 1. Run `jps` to check that it is finished. (no `datastax_3_1_4-1.0-jar-with-dependencies.jar` process left, may take a bit longer time
7. Run `parallel.sh` to start the parallel readers and writers. Each of them is dedicated to only one node according according to our client design. Then run `jps` to wait all of them being finished. However, there will be always two remaining. They are the reader and writer for node3. Checking the client log file `client-read-3.out` and `client-write-3.out` to know that they failed.
8. Run `./stop-cluster.sh` to stop the nodes.

## Explanation
* **Background**:
  * **Concurrency**: During startup of Cassandra nodes, the nonPeriodicTask thread has potential to be scheduled many times to tidy the SSTable, either by manually calling Flush or automatically compaction. Also, nonPeriodicTask has the potential to schedule itself for next SSTable tidy operation. So it is very likely there is short delay for the scheduling of SSTable tidy task. Also during SSTable tidying in nonPeriodicTask thread.
  * **Fault**: As described in *https://issues.apache.org/jira/browse/CASSANDRA-17564*, `Files.delete(file.toPath())` has potential to throw IOException. When handling it, if the DaemonStartup is not completed, the node will be killed. However, it will be tolerated after the startup. Note that there is no synchronization between the main Thread and nonPeriodicTask thread, so it is possible that the IOException happens after the startup.
* **Design of Reproduction of Symptom**: Generally the IOException should cause the death of the node. We tried to combine the aforementioned concurrency and fault condition to see what will happen if the IOException happens after the startup completes. To simulate this, we do the following experiment: at node 3, in the `tidy()` function called by `CompactionManager`, we delay the schedule of them, each by 1 second (5 injected delays in total). Then for the `Files.delete(file.toPath());` that is called by it, we manually throw IOException the 10-th time this place is traversed.
* **Result**: The experiment can similate the thrown IOException after the startup completes at node 3. Although the concurrency and fault are manually injected by us, we think in real world it is possible to happen. The experiment results show that the thrown IOException is tolerated as we analyzed. Then we use Datastax Cassandra client to create the data and do random read/write. Then fianlly we found that the node 3 (IOException injected) can not perform client read/write operation while others can. So this means that this node should be killed when that exception is thrown.

## The Call Stack of the IOException
In Cassandra-3.11.10:
```
java.lang.Thread#run:748
org.apache.cassandra.concurrent.NamedThreadFactory#lambda$threadLocalDeallocator$0:84
java.util.concurrent.ThreadPoolExecutor$Worker#run:624
java.util.concurrent.ThreadPoolExecutor#runWorker:1149
java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask#run:293
java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask#access$201:180
java.util.concurrent.FutureTask#run:266
java.util.concurrent.Executors$RunnableAdapter#call:511
org.apache.cassandra.io.sstable.format.SSTableReader$InstanceTidier$1#run:2228
org.apache.cassandra.utils.concurrent.Ref#release:119
org.apache.cassandra.utils.concurrent.Ref$State#release:225
org.apache.cassandra.utils.concurrent.Ref$GlobalState#release:326
org.apache.cassandra.io.sstable.format.SSTableReader$GlobalTidy#tidy:2323
org.apache.cassandra.db.lifecycle.LogTransaction$SSTableTidier#run:386
org.apache.cassandra.db.lifecycle.LogTransaction#delete:243
```
