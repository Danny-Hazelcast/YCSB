#!/usr/bin/expect -d
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

    TOTAL_NODES=$[$NODES_PER_JVM*$JVMS_PER_BOX*$BOX_COUNT]

    echo "total nodes = ${TOTAL_NODES}"

    count=0
    lastone=$[$BOX_COUNT*$JVMS_PER_BOX-1]

    for machine in $MACHINES
    do
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )

        #repeat for number of JVMS per machine
        i=0
        while [ $i -lt $JVMS_PER_BOX ]
        do
            echo "Starting on ${machine} JVM${i} with ${NODES_PER_JVM} Nodes, at version ${VERSION}"
            if [ ${count} == ${lastone} ]; then

                echo "starting last one ${count}"

                expect -c '
                set timeout 90
                spawn ssh '"${USER}"'@'"${ADDRESS}"' -p '"${PORT}"' "java -jar '"${TARGET_DIR}"'/'"${VERSION}"'/target/*.jar '"${NODES_PER_JVM}"' '"${TOTAL_NODES}"'"
                expect {
                "===>>CLUSTERED<<===" { exit 22}
                timeout {exit -1}
                }
                '

                if [ ${?} == 22 ]; then
                    echo "CLUSTERED"
                else
                    echo "!!! FAILED TO FORM THE FULL ${TOTAL_NODES} NODE CLUSTER !!!"
                fi

            else
                ssh ${USER}@${ADDRESS} -p ${PORT} "java -jar ${TARGET_DIR}/${VERSION}/target/*.jar ${NODES_PER_JVM} ${TOTAL_NODES} > ${TARGET_DIR}/${VERSION}/node${i}.out 2>&1" &
            fi

            i=$[$i+1]
            count=$[$count+1]
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

    echo "total inserts=${TOTAL_RECORDS}"

    START_IDX=0;
    for machine in $MACHINES
    do
        ADDRESS=$( address ${machine} )
	    PORT=$( port ${machine} )

	    #repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $DB_CLIENTS_PER_BOX ]
        do

            ssh ${USER}@${ADDRESS} -p ${PORT} "./${TARGET_DIR}/bin/ycsb load ${VERSION} -P ${TARGET_DIR}/workloads/${WORKLOAD} -P ${TARGET_DIR}/${DB_CLIENT_PROPS} -p insertstart=${START_IDX} -p insertcount=${INSERTS_PER_CLIENT} -p recordcount=${TOTAL_RECORDS} -s > ${TARGET_DIR}/${VERSION}/dbClient${i}-${WORKLOAD}-loadResult.txt 2>${TARGET_DIR}/${VERSION}/dbClient${i}.out" &
            echo "Starting on ${machine} DB-Client ${i} Load phase of ${WORKLOAD} inserting ${INSERTS_PER_CLIENT} for idx ${START_IDX}"
            START_IDX=$[$START_IDX+$INSERTS_PER_CLIENT]

            i=$[$i+1]
        done
    done
    wait
    echo "=====Load Phase Complete====="
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

            ssh ${USER}@${ADDRESS} -p ${PORT} "./${TARGET_DIR}/bin/ycsb run ${VERSION} -P ${TARGET_DIR}/workloads/${WORKLOAD} -P ${TARGET_DIR}/${DB_CLIENT_PROPS} -p recordcount=${TOTAL_RECORDS} -s > ${TARGET_DIR}/${VERSION}/dbClient${i}-${WORKLOAD}-runResult.txt 2>${TARGET_DIR}/${VERSION}/dbClient${i}.out" &
            echo "Starting on ${machine} DB-Client ${i} Transacton phase of ${WORKLOAD}"

            i=$[$i+1]
         done
    done
    wait
    echo "=====Run Phase Complete====="
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


function combineResults {
    DESTINATION_DIR=$1
    VERSION=$2
    FILE_NAMES=$3

    java -jar resultcombine/target/ResultCombine-0.1.4.jar ${DESTINATION_DIR}/${VERSION} "loadResult" > ${DESTINATION_DIR}/${VERSION}/loadReport.csv
    java -jar resultcombine/target/ResultCombine-0.1.4.jar ${DESTINATION_DIR}/${VERSION} "runResult"  > ${DESTINATION_DIR}/${VERSION}/runReport.csv
}


function killAllJava {

    for machine in $MACHINES
    do
        ADDRESS=$(address ${machine} )
	    PORT=$( port ${machine} )

        ssh ${USER}@${ADDRESS} -p ${PORT} "killall -9 java"
    done

}