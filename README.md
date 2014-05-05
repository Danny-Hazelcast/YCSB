DISTRIBUTED Yahoo! Cloud System Benchmark (YCSB)
====================================

Requirements
------------

1. ssh client

2. check that the command line utility "expect" is installed on the machines, that will run your cluster

Getting Started
---------------

1. the original readme is renamed as

        original-README.md

2. Set the USER variable of the global.sh

        you will need to set the USER variable to allow ssh access on to the remote machines
        you will need to set up your public/private key pair so that ssh will not prompt for a password

3. Installing DISTRIBUTED YCSB run

        ./install.sh

        this will install the YCSB system on all machines required to run the performance tests
        default to localhost

4. Run YCSB on DISTRIBUTED machines.
    
        ./go.sh [outputDirectory]

        Running the `go.sh` script with an optional output directory will...

            for each type of DB/CLUSTER system listed in SYSTEMS variable of global.sh
                Create a cluster as defined by the variables in the CLUSTER VARIABLES section of global.sh
                Check that the cluster has formed correctly
                Run the original YCSB performance test as defined by the variables in the LOAD PRODUCER VARIABLES section of global.sh
            Produce a directory (default /report) containing the results of the run

5. Configure the CLUSTER VARIABLES section of global.sh

        Edit these variables in global.sh to control how the cluster is formed

        CLUSTER_MACHINES
            List of IP addresses that will run the cluster nodes

        CLUSTER_JVMS_PER_BOX
            each of the machines can run multiple "cluster" JVM's

        CLUSTER_NODES_PER_JVM=1
            each of the "cluster" JVM's can run multiple Nodes

6. Configure the LOAD PRODUCER VARIABLES section of global.sh

        Edit these variables in global.sh to control how much load will be targeted at the cluster

        LOAD_MACHINES
            List of IP addresses that will run the load producing DbClients of YCSB

        DB_CLIENTS_PER_BOX
            each machine can run multiple DbClients

        NODES_PER_DB_CLIENT
            number of nodes to be started in each DBClient

        CLIENT_NODE
            boolean value showing type of nodes to be started in each DBClient, client or cluster member

        INSERTS_PER_DB_CLIENT
            How much load each DBClient will produce in the "LOAD" phase of YCSB

        OPERATIONS_PER_DB_CLIENT=1000
            How much load each DBClient will produce in the "TRANSACTION" phase of the YCSB system

        WORKLOAD
            the name of the YCSB workload file that YCSB will use to control the "TRANSACTION" phase
            see original-README.md for more information about the workload file



Adding a new system
-------------------

1. see original-README.md for how to implement a YCSB DB client interface.


2. DISTRIBUTED YCSB extra requirements

    requires that your target jar will be runnable. and define a static void main which will be passed 2 command line arguments:

            1) the number of cluster nodes to start in this JVM
            2) the target cluster size, the final size of the cluster that will be formed

    you are required to check the size of the cluster that forms and on equaling the target size print to std out

            ===>>CLUSTERED<<===

    this way DISTRIBUTED YCSB can coordinate the YCSB load and run phases




