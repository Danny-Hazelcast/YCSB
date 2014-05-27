#!/bin/bash
. functions.sh

OUTPUT_DIR="../report"
PROP_FILE="dbclient.properties"

if [ "$1" != "" ]; then
    OUTPUT_DIR=../$1
fi

rm -rf ${OUTPUT_DIR}

createPropertisFile "../" ${PROP_FILE}

for VERSION in ${SYSTEMS[@]}
do
    echo "====== Init Cluster ========"
    initCluster ${VERSION} ${CLUSTER_JVMS_PER_BOX} ${CLUSTER_NODES_PER_JVM}

    if [ ${?} == 0 ]; then

        #CLIENT_NODE="true"
        #createPropertisFile "../" ${PROP_FILE}

        echo "====== Load phase ========"
        loadPhase ${VERSION} ${DB_CLIENTS_PER_BOX} ${INSERTS_PER_DB_CLIENT} ${OPERATIONS_PER_DB_CLIENT} "dbclient.properties" ${WORKLOAD}


        #CLIENT_NODE="false"
        #createPropertisFile "../" ${PROP_FILE}


        echo "====== Transaction phase ========"
        transactionPhase ${VERSION} ${DB_CLIENTS_PER_BOX} ${INSERTS_PER_DB_CLIENT} ${OPERATIONS_PER_DB_CLIENT} "dbclient.properties" ${WORKLOAD}

        echo "====== Getting results ========"

        downLoadResults ${VERSION} ${DB_CLIENTS_PER_BOX} ${WORKLOAD} ${OUTPUT_DIR}
        combineResults ${OUTPUT_DIR} ${VERSION}
    fi

    echo "====== Killing phase ========"
    killAllJava
    sleep 5
done


echo "====== Producing Report  ========"
saveRunInfo ${VERSION} ${CLUSTER_JVMS_PER_BOX} ${CLUSTER_NODES_PER_JVM} ${DB_CLIENTS_PER_BOX} "dbclient.properties" ${WORKLOAD} ${OUTPUT_DIR}


totalInserts=$[${#LOAD_MACHINES[@]}*${DB_CLIENTS_PER_BOX}*${INSERTS_PER_DB_CLIENT}]
totalOpps=$[${#LOAD_MACHINES[@]}*${DB_CLIENTS_PER_BOX}*${OPERATIONS_PER_DB_CLIENT}]

reportResults ${OUTPUT_DIR} ${totalInserts} ${totalOpps}