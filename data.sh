#!/bin/bash

USER=danny
TARGET_DIR=ycsb


MACHINE1='192.168.2.101'
MACHINE2='192.168.2.102'
MACHINE3='192.168.2.103'
MACHINE4='192.168.2.104'
MACHINES="${MACHINE1} ${MACHINE2} ${MACHINE3} ${MACHINE4}"


HZ26="hz26"
HZ30="hz30"
HZ31="hz31"
HZ32="hz32"
VERSION=${HZ32}


WORKLOADa="workloada"
WORKLOADb="workloadb"
WORKLOADc="workloadc"
WORKLOADd="workloadd"
WORKLOADe="workloade"
WORKLOADf="workloadf"
WORKLOADZ="workloadZ"
WORKLOAD=${WORKLOADZ}


CLUSTER_JVMS_PER_BOX=4
CLUSTER_NODES_PER_JVM=2


DB_CLIENTS_PER_BOX=8
THREADS_PER_DB_CLIENT=4