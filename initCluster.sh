#!/bin/bash
. functions.sh


echo "Starting Cluster formation"
initCluster ${VERSION} ${CLUSTER_JVMS_PER_BOX} ${CLUSTER_NODES_PER_JVM}