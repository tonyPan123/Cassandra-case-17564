
## Usage
1. Modify the parameters in `workload.sh`, e.g., host, port.
2. Start a Cassandra cluster of 3 nodes, and wait until all of them are available to accept clients (see "Startup complete" in the log.
3. Run `create.sh` to create a keyspace and table. The requests are sent to node 1.
4. Run `parallel.sh` to start the parallel readers and writers. Each of them is dedicated to only one node according according to our client design.

