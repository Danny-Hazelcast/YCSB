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
    JVMS=$2
    NODES_PER_JVM=$3


    for machine in $MACHINES
    do
        ADDRESS=$( addregss ${machine} )
	    PORT=$( port ${machine} )

        #repeat for number of JVMS per machine
        i=0
        while [ $i -lt $JVMS ]
        do
            ssh ${USER}@${ADDRESS} -p ${PORT} "java -jar ${TARGET_DIR}/${VERSION}/target/*.jar ${NODES_PER_JVM} > ${TARGET_DIR}/${VERSION}/node${i}.out" &
            echo "Starting on ${machine} JVM${i} with ${NODES_PER_JVM} Nodes, at version ${VERSION}"

            i=$[$i+1]
        done
    done
}


echo "Starting Cluster formation"
initCluster $HZ32 4 2