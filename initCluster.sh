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

function initCluster {
    VERSION=$1

    for machine in $MACHINES
    do
        #repeat for number of JVMS per machine
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )

        ssh ${USER}@${ADDRESS} -p ${PORT} "java -jar ${TARGET_DIR}/${VERSION}/target/*.jar > ${TARGET_DIR}/node.out" &

        echo "Starting ${VERSION} Node(s) on ${machine}"
    done
}


initCluster $HZ32
echo "Waiting for Cluster formation"