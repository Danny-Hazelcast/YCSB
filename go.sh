#!/bin/bash
. functions.sh


HZ26="hz26"
HZ30="hz30"
HZ31="hz31"
HZ32="hz32"
VERSIONS=("${HZ26}" "${HZ30}" "${HZ31}" "${HZ32}")


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


DB_CLIENTS_PER_BOX=4
INSERTS_PER_DB_CLIENT=1000

OUTPUT_DIR="report"


    for VERSION in ${VERSIONS[@]}
    do
        initCluster ${VERSION} ${CLUSTER_JVMS_PER_BOX} ${CLUSTER_NODES_PER_JVM}

        if [ ${?} == 0 ]; then

            loadPhase ${VERSION} ${DB_CLIENTS_PER_BOX} ${INSERTS_PER_DB_CLIENT} "2client.properties" ${WORKLOAD}
            transactionPhase ${VERSION} ${DB_CLIENTS_PER_BOX} ${INSERTS_PER_DB_CLIENT} "2client.properties" ${WORKLOAD}

            downLoadResults ${VERSION} ${DB_CLIENTS_PER_BOX} ${WORKLOAD} ${OUTPUT_DIR}
            saveRunInfo ${VERSION} ${CLUSTER_JVMS_PER_BOX} ${CLUSTER_NODES_PER_JVM} ${DB_CLIENTS_PER_BOX} "2client.properties" ${WORKLOAD} ${OUTPUT_DIR}

            combineResults ${OUTPUT_DIR} ${VERSION}

        fi

        killAllJava
    done

    reportResults ${OUTPUT_DIR}
