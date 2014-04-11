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
# just keeping it singel jvm and thread per machien on the load phase, as this tool ycsb aint that good at this load phase more suted to trad database stuff
function runLoadPhase {
    VERSION=$1
    WORKLOAD=$2
    DB_CLIENT_PROPS=$3

    for machine in $MACHINES
    do
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )
        ssh ${USER}@${ADDRESS} -p ${PORT} "./${TARGET_DIR}/bin/ycsb load ${VERSION} -P ${TARGET_DIR}/workloads/${WORKLOAD} -P ${TARGET_DIR}/${DB_CLIENT_PROPS} -s -threads 1 > ${TARGET_DIR}/${VERSION}/${WORKLOAD}-loadResult.txt" &
        echo "Starting Load phase of ${WORKLOAD} from ${machine} JVM 1"
    done
}

function runTransactionPhase {
    VERSION=$1
    WORKLOAD=$2
    DB_CLIENT_PROPS=$3

    for machine in $MACHINES
    do
        #repeat for number of JVMS per machine to make load
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )
        ssh ${USER}@${ADDRESS} -p ${PORT} "./${TARGET_DIR}/bin/ycsb run ${VERSION} -P ${TARGET_DIR}/workloads/${WORKLOAD} -P ${TARGET_DIR}/${DB_CLIENT_PROPS} -s > ${TARGET_DIR}/${VERSION}/${WORKLOAD}-runResult.txt" &
        echo "Starting Transaction phase of ${WORKLOAD} from ${machine} JVM 1"
    done
}

runLoadPhase $HZ32 "workloada" "2client.properties"
echo "Waiting for Load Phase completion"
sleep 30s

runTransactionPhase $HZ32 "workloada" "2client.properties"