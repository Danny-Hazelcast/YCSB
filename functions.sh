#!/usr/bin/expect -d
. golbal.sh

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

	address=$( address ${MACHINE} )
	port=$( port ${MACHINE} )

	echo ===============================================================
	echo Installing YCSB on ${MACHINE}
	echo ===============================================================

	ssh ${USER}@${address} -p ${port} "rm -fr ${BASE_DIR}"
	ssh ${USER}@${address} -p ${port} "mkdir ${BASE_DIR}"

	scp -P ${port} ${ZIP_NAME} ${USER}@${address}:${BASE_DIR}/${ZIP_NAME}
	echo Unzipping ${ZIP_NAME}
	ssh ${USER}@${address} -p ${port}  "unzip -q ${BASE_DIR}/${ZIP_NAME} -d ${BASE_DIR}"

	echo ===============================================================
	echo Finished installing YCSB on ${MACHINE}
	echo ===============================================================
}


function initCluster {
    version=$1
    jvmsPerBox=$2
    nodesPerBox=$3

    totalNodes=$[jvmsPerBox*nodesPerBox]
    lastOne=$[${#MACHINES[@]}*jvmsPerBox-1]

    echo "totalNodes = ${totalNodes}"

    count=0
    for machine in ${MACHINES}
    do
        address=$( address ${machine} )
	    port=$( port ${machine} )

        i=0
        while [ $i -lt ${jvmsPerBox} ]
        do
            echo "Starting on ${machine} JVM${i} with ${nodesPerBox} Nodes, at version ${version}"
            if [ ${count} == ${lastOne} ]; then

                echo "starting last one ${count}"

                expect -c '
                set timeout 90
                spawn ssh '"${USER}"'@'"${address}"' -p '"${port}"' "java -jar '"${BASE_DIR}"'/'"${version}"'/target/*.jar '"${nodesPerBox}"' '"${totalNodes}"'"
                expect {
                "===>>CLUSTERED<<===" { exit 22}
                timeout {exit -1}
                }
                '

                if [ ${?} == 22 ]; then
                    echo "=====CLUSTERED==== version ${version}"
                    return 0
                else
                    echo "!!! FAILED TO FORM THE FULL ${totalNodes} NODE CLUSTER !!!  version ${version}"
                    return 2
                fi

            else
                ssh ${USER}@${address} -p ${port} "java -jar ${BASE_DIR}/${version}/target/*.jar ${nodesPerBox} ${totalNodes} > ${BASE_DIR}/${version}/node${i}.out 2>&1" &
            fi

            i=$[$i+1]
            count=$[$count+1]
        done
    done
    echo "SOME THING REALLY WENT WRONG HEAR"
    return 2
}


function loadPhase {
    version=$1
    clientsPerBox=$2
    insertsPerClient=$3
    clientProps=$4
    workload=$5

    totalRecords=$[${#MACHINES[@]}*clientsPerBox*insertsPerClient]
    echo "=====Running Load Phase====="
    echo "totalRecords to insert=${totalRecords}"

    pids=()
    startIdx=0;
    for machine in $MACHINES
    do
        address=$( address ${machine} )
	    port=$( port ${machine} )

        i=0
        while [ $i -lt $clientsPerBox ]
        do
            ssh ${USER}@${address} -p ${port} "./${BASE_DIR}/bin/ycsb load ${version} -P ${BASE_DIR}/workloads/${workload} -P ${BASE_DIR}/${clientProps} -p insertstart=${startIdx} -p insertcount=${insertsPerClient} -p recordcount=${totalRecords} -s > ${BASE_DIR}/${version}/dbClient${i}-${workload}-loadResult.txt 2>${BASE_DIR}/${version}/dbClient${i}.out" &
            pids+=($!)
            echo "Starting on ${machine} DB-Client ${i} Load phase of ${workload} inserting ${insertsPerClient} for idx ${startIdx} version ${version}"
            startIdx=$[$startIdx+$insertsPerClient]

            i=$[$i+1]
        done
    done

    for id in $pids
    do
       wait ${id}
    done

    echo "=====Load Phase Complete====="
}


function transactionPhase {
    version=$1
    clientsPerBox=$2
    insertsPerClient=$3
    clientProps=$4
    workload=$5

    totalRecords=$[${#MACHINES[@]}*clientsPerBox*insertsPerClient]


    echo "=====Running work Phase====="
    pids=()
    for machine in $MACHINES
    do
        address=$( address ${machine} )
	    port=$( port ${machine} )

	    #repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $clientsPerBox ]
        do

            ssh ${USER}@${address} -p ${port} "./${BASE_DIR}/bin/ycsb run ${version} -P ${BASE_DIR}/workloads/${workload} -P ${BASE_DIR}/${clientProps} -p recordcount=${totalRecords} -s > ${BASE_DIR}/${version}/dbClient${i}-${workload}-runResult.txt 2>${BASE_DIR}/${version}/dbClient${i}.out" &
            pids+=($!)
            echo "Starting on ${machine} DB-Client ${i} Transacton phase of ${workload} version ${version}"

            i=$[$i+1]
         done
    done

    for id in $pids
    do
       wait ${id}
    done

    echo "=====Work Phase Complete====="
}



function tailClusterOutput {
    version=$1
    jvmsPerBox=$2

    for machine in $MACHINES
    do
        address=$( address ${machine} )
	    port=$( port ${machine} )

        #repeat for number of JVMS per machine
        i=0
        while [ $i -lt $jvmsPerBox ]
        do
            ssh ${USER}@${address} -p ${port} "tail -f ${BASE_DIR}/${version}/node${i}.out" &
            echo "tailling output of ${machine} JVM${i} with, at version ${version}"

            i=$[$i+1]
        done
    done
}


function tailDbClientOutput {
    version=$1
    clientsPerBox=$2

    for machine in $MACHINES
    do
        address=$( address ${machine} )
	    port=$( port ${machine} )

	    #repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $clientsPerBox ]
        do

            ssh ${USER}@${address} -p ${port} "tail -f ${BASE_DIR}/${version}/dbClient${i}.out" &
            echo "tailing on ${machine} DB-Client ${i} output"

            i=$[$i+1]
        done
    done
}



function downLoadResults {
    version=$1
    clientsPerBox=$2
    workload=$3
    outDir=$4

    mkdir ${outDir}
    mkdir ${outDir}/${version}

    box=0
    for machine in $MACHINES
    do
        address=$(address ${machine} )
	    port=$( port ${machine} )

        mkdir ${outDir}/${version}/box${box}

#       repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $clientsPerBox ]
        do

	        scp -P ${port} -q -r ${USER}@${address}:${BASE_DIR}/${version}/dbClient${i}-${workload}-loadResult.txt ${outDir}/${version}/box${box}
	        scp -P ${port} -q -r ${USER}@${address}:${BASE_DIR}/${version}/dbClient${i}-${workload}-runResult.txt ${outDir}/${version}/box${box}
            echo "downLoading Results of ${version} ${workload} from DB Client ${i} on ${machine} to ${outDir}/${version}/box${box}"

            ssh ${USER}@${address} -p ${port} "rm -f ${BASE_DIR}/${version}/dbClient${i}-${workload}-loadResult.txt"
            ssh ${USER}@${address} -p ${port} "rm -f ${BASE_DIR}/${version}/dbClient${i}-${workload}-runResult.txt"

            i=$[$i+1]
        done
        box=$[$box+1]
    done
}


function combineResults {
    outDir=$1
    version=$2

    java -jar resultcombine/target/ResultCombine-0.1.4.jar ${outDir}/${version} "loadResult" > ${outDir}/${version}/loadReport.csv
    java -jar resultcombine/target/ResultCombine-0.1.4.jar ${outDir}/${version} "runResult"  > ${outDir}/${version}/runReport.csv
}


function killAllJava {

    for machine in $MACHINES
    do
        address=$(address ${machine} )
	    port=$( port ${machine} )

        ssh ${USER}@${address} -p ${port} "killall -9 java"
    done
}