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


function downLoadResults {
    VERSION=$1
    WORKLOAD=$2
    DESTINATION_DIR=$3

    mkdir ${DESTINATION_DIR}/${VERSION}/${WORKLOAD}

    for machine in $MACHINES
    do
        #loop for multi JVMS per Machien
        ADDRESS=$(address ${machine} )
	    PORT=$( port ${machine} )
	    echo "downLoading Results of ${VERSION} ${WORKLOAD} from ${machine} JVM 1...."

	    scp -P ${PORT} -q -r ${USER}@${ADDRESS}:${TARGET_DIR}/${VERSION}/${WORKLOAD}-loadResult.txt ${DESTINATION_DIR}/${VERSION}/${WORKLOAD}
	    scp -P ${PORT} -q -r ${USER}@${ADDRESS}:${TARGET_DIR}/${VERSION}/${WORKLOAD}-runResult.txt ${DESTINATION_DIR}//${VERSION}/${WORKLOAD}
    done
}


downLoadResults $HZ32 "workloada" "/result"