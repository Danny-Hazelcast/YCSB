#!/bin/bash

#=== Username for ssh connection e.g. ssh root@127.0.0.1
#
USER=danny
#
#===============================================


#the base install dir of the YCSB tool on the remote boxes
BASE_DIR=ycsb


#===CONVINENCE VARIABLES===========================================
#
# A choice of boxes to run on
localhost='127.0.0.1'
box1='192.168.2.101'
box2='192.168.2.102'
box3='192.168.2.103'
box4='192.168.2.104'

# A choice of systems that are setup and ready to be tested
hz26="hz26"
hz30="hz30"
hz31="hz31"
hz32="hz32"
gg="gridgain"

#a choice of workload files in the workloads directory of this project
workloadA="workloada"
workloadZ="workloadZ"
#
#=====================================================================



#===SYSTEMS VARIABLES edit this list to control which version to test======
#
# A list of systems to be tested
SYSTEMS=("${gg}" "${hz26}" "${hz30}" "${hz31}" "${hz32}")
#
#=========================================================



#===CLUSTER VARIABLES edit these variables to control how the cluster is formed ===
#
# List of boxes that will run the cluster nodes
CLUSTER_MACHINES=("${localhost}")

# number of jvms to start on each box in CLUSTER_MACHINES
CLUSTER_JVMS_PER_BOX=2

# number of nodes to be started in each JVM on each box
CLUSTER_NODES_PER_JVM=1
#
#==================================================================



#===LOAD PRODUCER VARIABLES edit to control where and how YCSB will run==========================
#
# A list of boxes that will run the load producing DBClients of the YCSB system
LOAD_MACHINES=("${localhost}")

# number of DBClients to be started on each box in LOAD_MACHINES
DB_CLIENTS_PER_BOX=2

# How much load each DBClient will produce in the LOAD phase of the YCSB system
INSERTS_PER_DB_CLIENT=1000

# How much load each DBClient will produce in the TRANSACTION phase of the YCSB system
OPERATIONS_PER_DB_CLIENT=1000

# the name of the YCSB workload file that YCSB will use to control the TRANSACTION phase controls the update/read split, request distribution,
WORKLOAD=${workloadZ}
#
#=========================================================================================



#===DONT PLAY WITH THIS=======
#
ALL_MACHINES=${CLUSTER_MACHINES[*]}" "${LOAD_MACHINES[*]}
ALL_MACHINES=$(echo "${ALL_MACHINES[@]}" | awk '!arr[$1]++' RS=" ")
#
#=============================







