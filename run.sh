#!/bin/bash

USER=danny
TARGET_DIR=ycsbtmp

MACHINE1='192.168.2.101'
MACHINE2='192.168.2.102'
MACHINE3='192.168.2.103'
MACHINE4='192.168.2.104'
MACHINES="${MACHINE1} ${MACHINE2} ${MACHINE3} ${MACHINE4}"

HZ26="hz26"
HZ30="hz30"
HZ31="hz31"
HZ32="hz32"

function address {
	MACHINE=$1

	if echo ${MACHINE}| grep ':' > /dev/null; then
		ADDRESS=${MACHINE%:*}
		echo ${ADDRESS}
	else
		echo ${MACHINE}
	fi
}

function port {
	MACHINE=$1

	if echo ${MACHINE}| grep ':' > /dev/null; then
		PORT=${MACHINE:$(expr index "$MACHINE" ":")}
		echo ${PORT}
	else
		echo 22
	fi
}


# load phse on multi machiens needs propertys to be set to div up the key load to each machien,
# ThreadCount in workLoad file
function runLoadPhase {
    VERSION=$1
    MAX_DB_CLIENTS=$2
    WORKLOAD=$3
    DB_CLIENT_PROPS=$4
    INSERTS_PER_CLIENT=$5

    START_IDX=0;
    for machine in $MACHINES
    do
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )

	    #repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $MAX_DB_CLIENTS ]
        do

            ssh ${USER}@${ADDRESS} -p ${PORT} "./${TARGET_DIR}/bin/ycsb load ${VERSION} -P ${TARGET_DIR}/workloads/${WORKLOAD} -P ${TARGET_DIR}/${DB_CLIENT_PROPS} -p insertstart=${START_IDX} -p insertcount=${INSERTS_PER_CLIENT} -s > ${TARGET_DIR}/${VERSION}/dbClient${i}{WORKLOAD}-loadResult.txt" &
            echo "Starting on ${machine} DB-Client ${i} Load phase of ${WORKLOAD} inserting ${INSERTS_PER_CLIENT} for idx ${START_IDX}"
            START_IDX=$[$START_IDX+$INSERTS_PER_CLIENT]

            i=$[$i+1]
        done
    done
}

function runTransactionPhase {
    VERSION=$1
    MAX_DB_CLIENTS=$2
    WORKLOAD=$3
    DB_CLIENT_PROPS=$4

    for machine in $MACHINES
    do
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )

	    #repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $MAX_DB_CLIENTS ]
        do

            ssh ${USER}@${ADDRESS} -p ${PORT} "./${TARGET_DIR}/bin/ycsb run ${VERSION} -P ${TARGET_DIR}/workloads/${WORKLOAD} -P ${TARGET_DIR}/${DB_CLIENT_PROPS} -s > ${TARGET_DIR}/${VERSION}/dbClient${i}{WORKLOAD}-runResult.txt" &
            echo "Starting on ${machine} DB-Client ${i} Transacton phase of ${WORKLOAD}"

            i=$[$i+1]
         done
    done
}

runLoadPhase $HZ32 4 "workloada" "2client.properties" 1000
echo "Waiting for Load Phase completion"
sleep 30s

runTransactionPhase $HZ32 4 "workloada" "2client.properties"