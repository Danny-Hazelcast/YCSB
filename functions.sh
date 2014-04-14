#!/bin/bash
. data.sh

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

function zipCurrentDir {
    echo ===============================================================
    echo zipping pwd
    echo ===============================================================

    NAME=$1
    zip -q -r ${NAME} .
}


function install {
	MACHINE=$1
	ZIP_NAME=$2

	ADDRESS=$( address ${MACHINE} )
	PORT=$( port ${MACHINE} )

	echo ===============================================================
	echo Installing YCSB on ${MACHINE}
	echo ===============================================================

	ssh ${USER}@${ADDRESS} -p ${PORT} "rm -fr ${TARGET_DIR}"
	ssh ${USER}@${ADDRESS} -p ${PORT} "mkdir ${TARGET_DIR}"

	scp -P ${PORT} ${ZIP_NAME} ${USER}@${ADDRESS}:${TARGET_DIR}/${ZIP_NAME}
	echo Unzipping ${ZIP_NAME}
	ssh ${USER}@${ADDRESS} -p ${PORT}  "unzip -q ${TARGET_DIR}/${ZIP_NAME} -d ${TARGET_DIR}"

	echo ===============================================================
	echo Finished installing YCSB on ${MACHINE}
	echo ===============================================================
}


function initCluster {
    VERSION=$1
    JVMS_PER_BOX=$2
    NODES_PER_JVM=$3


    for machine in $MACHINES
    do
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )

        #repeat for number of JVMS per machine
        i=0
        while [ $i -lt $JVMS_PER_BOX ]
        do
            ssh ${USER}@${ADDRESS} -p ${PORT} "java -jar ${TARGET_DIR}/${VERSION}/target/*.jar ${NODES_PER_JVM} > ${TARGET_DIR}/${VERSION}/node${i}.out 2>&1" &
            echo "Starting on ${machine} JVM${i} with ${NODES_PER_JVM} Nodes, at version ${VERSION}"

            i=$[$i+1]
        done
    done
}


function tailClusterOutput {
    VERSION=$1
    JVMS_PER_BOX=$2

    for machine in $MACHINES
    do
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )

        #repeat for number of JVMS per machine
        i=0
        while [ $i -lt $JVMS_PER_BOX ]
        do
            ssh ${USER}@${ADDRESS} -p ${PORT} "tail -f ${TARGET_DIR}/${VERSION}/node${i}.out" &
            echo "tailling output of ${machine} JVM${i} with, at version ${VERSION}"

            i=$[$i+1]
        done
    done
}


function runLoadPhase {
    VERSION=$1
    DB_CLIENTS_PER_BOX=$2
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
        while [ $i -lt $DB_CLIENTS_PER_BOX ]
        do

            ssh ${USER}@${ADDRESS} -p ${PORT} "./${TARGET_DIR}/bin/ycsb load ${VERSION} -P ${TARGET_DIR}/workloads/${WORKLOAD} -P ${TARGET_DIR}/${DB_CLIENT_PROPS} -p insertstart=${START_IDX} -p insertcount=${INSERTS_PER_CLIENT} -s > ${TARGET_DIR}/${VERSION}/dbClient${i}-${WORKLOAD}-loadResult.txt 2>${TARGET_DIR}/${VERSION}/dbClient${i}.out" &
            echo "Starting on ${machine} DB-Client ${i} Load phase of ${WORKLOAD} inserting ${INSERTS_PER_CLIENT} for idx ${START_IDX}"
            START_IDX=$[$START_IDX+$INSERTS_PER_CLIENT]

            i=$[$i+1]
        done
    done
}


function runTransactionPhase {
    VERSION=$1
    DB_CLIENTS_PER_BOX=$2
    WORKLOAD=$3
    DB_CLIENT_PROPS=$4

    for machine in $MACHINES
    do
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )

	    #repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $DB_CLIENTS_PER_BOX ]
        do

            ssh ${USER}@${ADDRESS} -p ${PORT} "./${TARGET_DIR}/bin/ycsb run ${VERSION} -P ${TARGET_DIR}/workloads/${WORKLOAD} -P ${TARGET_DIR}/${DB_CLIENT_PROPS} -s > ${TARGET_DIR}/${VERSION}/dbClient${i}-${WORKLOAD}-runResult.txt 2>${TARGET_DIR}/${VERSION}/dbClient${i}.out" &
            echo "Starting on ${machine} DB-Client ${i} Transacton phase of ${WORKLOAD}"

            i=$[$i+1]
         done
    done
}


function tailDbClientOutput {
    VERSION=$1
    DB_CLIENTS_PER_BOX=$2


    for machine in $MACHINES
    do
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )

	    #repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $DB_CLIENTS_PER_BOX ]
        do

            ssh ${USER}@${ADDRESS} -p ${PORT} "tail -f ${TARGET_DIR}/${VERSION}/dbClient${i}.out" &
            echo "tailing on ${machine} DB-Client ${i} output"

            i=$[$i+1]
        done
    done
}



function downLoadResults {
    VERSION=$1
    DB_CLIENTS_PER_BOX=$2
    WORKLOAD=$3
    DESTINATION_DIR=$4

    mkdir ${DESTINATION_DIR}
    mkdir ${DESTINATION_DIR}/${VERSION}

    box=0
    for machine in $MACHINES
    do
        ADDRESS=$(address ${machine} )
	    PORT=$( port ${machine} )

        mkdir ${DESTINATION_DIR}/${VERSION}/box${box}

#       repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $DB_CLIENTS_PER_BOX ]
        do


	        scp -P ${PORT} -q -r ${USER}@${ADDRESS}:${TARGET_DIR}/${VERSION}/dbClient${i}-${WORKLOAD}-loadResult.txt ${DESTINATION_DIR}/${VERSION}/box${box}
	        scp -P ${PORT} -q -r ${USER}@${ADDRESS}:${TARGET_DIR}/${VERSION}/dbClient${i}-${WORKLOAD}-runResult.txt ${DESTINATION_DIR}/${VERSION}/box${box}
            echo "downLoading Results of ${VERSION} ${WORKLOAD} from DB Client ${i} on ${machine} "

            ssh ${USER}@${ADDRESS} -p ${PORT} "rm -f ${TARGET_DIR}/${VERSION}/dbClient${i}-${WORKLOAD}-loadResult.txt"
            ssh ${USER}@${ADDRESS} -p ${PORT} "rm -f ${TARGET_DIR}/${VERSION}/dbClient${i}-${WORKLOAD}-runResult.txt"

            i=$[$i+1]
        done
        box=$[$box+1]
    done
}


function killAllJava {

    for machine in $MACHINES
    do
        ADDRESS=$(address ${machine} )
	    PORT=$( port ${machine} )

        ssh ${USER}@${ADDRESS} -p ${PORT} "killall -9 java"
    done
}
