#!/usr/bin/expect -d
. global.sh

function address {
	box=$1

	if echo ${box}| grep ':' > /dev/null; then
		ADDRESS=${box%:*}
		echo ${ADDRESS}
	else
		echo ${box}
	fi
}

function port {
	box=$1

	if echo ${box}| grep ':' > /dev/null; then
		PORT=${box:$(expr index "$box" ":")}
		echo ${PORT}
	else
		echo 22
	fi
}

function zipCurrentDir {
    echo ===============================================================
    echo "zipping"
    echo ===============================================================

    NAME=$1
    zip -q -r ${NAME} ..
}


function install {
	box=$1
	zipFileName=$2

	address=$( address ${box} )
	port=$( port ${box} )

	echo ===============================================================
	echo Installing YCSB on ${box}
	echo ===============================================================

	ssh ${USER}@${address} -p ${port} "rm -fr ${BASE_DIR}"
	ssh ${USER}@${address} -p ${port} "mkdir ${BASE_DIR}"

	scp -r -P ${port} ${zipFileName} ${USER}@${address}:${BASE_DIR}/${zipFileName}
	echo Unzipping ${zipFileName}
	ssh ${USER}@${address} -p ${port}  "unzip -q ${BASE_DIR}/${zipFileName} -d ${BASE_DIR}"

	echo ===============================================================
	echo Finished installing YCSB on ${box}
	echo ===============================================================
}


function initCluster {
    version=$1
    jvmsPerBox=$2
    nodesPerJvm=$3

    numberOfBoxes=${#CLUSTER_MACHINES[@]}

    clusterSize=$[numberOfBoxes*jvmsPerBox*nodesPerJvm]
    lastOne=$[numberOfBoxes*jvmsPerBox-1]

    echo "expect cluster Size=${clusterSize} last JVM #${lastOne}"

    count=0
    for box in ${CLUSTER_MACHINES[@]}
    do
        address=$( address ${box} )
	    port=$( port ${box} )

        i=0
        while [ $i -lt ${jvmsPerBox} ]
        do
            echo "Starting on ${box} JVM${i} with ${nodesPerJvm} Nodes, at version ${version}"
            if [ ${count} == ${lastOne} ]; then

                echo "starting last JVM"

                expect -c '
                set timeout 90
                spawn ssh '"${USER}"'@'"${address}"' -p '"${port}"' "java -jar '"${BASE_DIR}"'/'"${version}"'/target/*.jar '"${nodesPerJvm}"' '"${clusterSize}"'"
                expect {
                "===>>CLUSTERED<<===" { exit 22}
                timeout {exit -1}
                }
                '

                if [ ${?} == 22 ]; then
                    echo "CLUSTERED CONFIRMED version ${version}"
                    return 0
                else
                    echo "!!! FAILED TO FORM THE FULL ${clusterSize} NODE CLUSTER !!!  version ${version}"
                    return 2
                fi

            else
                ssh ${USER}@${address} -p ${port} "java -jar ${BASE_DIR}/${version}/target/*.jar ${nodesPerJvm} ${clusterSize} > ${BASE_DIR}/${version}/node${i}.out 2>&1" &
            fi

            i=$[$i+1]
            count=$[$count+1]

            sleep 5
        done
    done
    echo "SOME THING REALLY WENT WRONG HEAR"
    return 2
}


function loadPhase {
    version=$1
    clientsPerBox=$2
    insertsPerClient=$3
    operationPerDbClient=$4
    clientProps=$5
    workload=$6

    totalRecords=$[${#LOAD_MACHINES[@]}*clientsPerBox*insertsPerClient]
    echo "totalRecords to insert=${totalRecords}"

    pids=()
    startIdx=0;
    for box in ${LOAD_MACHINES[@]}
    do
        address=$( address ${box} )
	    port=$( port ${box} )

        i=0
        while [ $i -lt $clientsPerBox ]
        do
            ssh ${USER}@${address} -p ${port} "sleep 30 && ./${BASE_DIR}/bin/ycsb load ${version} -P ${BASE_DIR}/workloads/${workload} -P ${BASE_DIR}/${clientProps} -p insertstart=${startIdx} -p insertcount=${insertsPerClient} -p recordcount=${totalRecords} -p operationcount=${operationPerDbClient} -s > ${BASE_DIR}/${version}/dbClient${i}-${workload}-loadResult.txt 2>${BASE_DIR}/${version}/dbClient${i}Load.out" &
            pids+=($!)
            echo "Starting on ${box} DB-Client ${i} Load phase of ${workload} inserting ${insertsPerClient} for idx ${startIdx} version ${version}"
            startIdx=$[$startIdx+$insertsPerClient]

            i=$[$i+1]
        done
    done

    for id in $pids
    do
       wait ${id}
    done
}


function transactionPhase {
    version=$1
    clientsPerBox=$2
    insertsPerClient=$3
    operationPerDbClient=$4
    clientProps=$5
    workload=$6

    totalRecords=$[${#LOAD_MACHINES[@]}*clientsPerBox*insertsPerClient]

    pids=()
    for box in ${LOAD_MACHINES[@]}
    do
        address=$( address ${box} )
	    port=$( port ${box} )

	    #repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $clientsPerBox ]
        do

            ssh ${USER}@${address} -p ${port} "./${BASE_DIR}/bin/ycsb run ${version} -P ${BASE_DIR}/workloads/${workload} -P ${BASE_DIR}/${clientProps} -p recordcount=${totalRecords} -p operationcount=${operationPerDbClient} -s > ${BASE_DIR}/${version}/dbClient${i}-${workload}-runResult.txt 2>${BASE_DIR}/${version}/dbClient${i}Trans.out" &
            pids+=($!)
            echo "Starting on ${box} DB-Client ${i} Transacton phase of ${workload} version ${version}"

            i=$[$i+1]
         done
    done

    for id in $pids
    do
       wait ${id}
    done
}



function tailClusterOutput {
    version=$1
    jvmsPerBox=$2

    for box in ${CLUSTER_MACHINES[@]}
    do
        address=$( address ${box} )
	    port=$( port ${box} )

        #repeat for number of JVMS per machine
        i=0
        while [ $i -lt $jvmsPerBox ]
        do
            ssh ${USER}@${address} -p ${port} "tail -f ${BASE_DIR}/${version}/node${i}.out" &
            echo "tailling output of ${box} JVM${i} with, at version ${version}"

            i=$[$i+1]
        done
    done
}


function tailDbClientOutput {
    version=$1
    clientsPerBox=$2

    for box in ${LOAD_MACHINES[@]}
    do
        address=$( address ${box} )
	    port=$( port ${box} )

	    #repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $clientsPerBox ]
        do

            ssh ${USER}@${address} -p ${port} "tail -f ${BASE_DIR}/${version}/dbClient${i}.out" &
            echo "tailing on ${box} DB-Client ${i} output"

            i=$[$i+1]
        done
    done
}



function downLoadResults {
    version=$1
    jvmsPerBox=$2

    clientsPerBox=$2
    workload=$3
    outDir=$4

    mkdir ${outDir}
    mkdir ${outDir}/${version}

    boxNumber=0
    for box in ${LOAD_MACHINES[@]}
    do
        address=$(address ${box} )
	    port=$( port ${box} )

        mkdir ${outDir}/${version}/box${boxNumber}

#       repeat for number of DB-Clients per machine
        i=0
        while [ $i -lt $clientsPerBox ]
        do

	        scp -P ${port} -q -r ${USER}@${address}:${BASE_DIR}/${version}/dbClient${i}-${workload}-loadResult.txt ${outDir}/${version}/box${boxNumber}
	        scp -P ${port} -q -r ${USER}@${address}:${BASE_DIR}/${version}/dbClient${i}-${workload}-runResult.txt ${outDir}/${version}/box${boxNumber}
            echo "downLoading Results of ${version} ${workload} from DB Client ${i} on ${box} to ${outDir}/${version}/box${boxNumber}"

            ssh ${USER}@${address} -p ${port} "rm -f ${BASE_DIR}/${version}/dbClient${i}-${workload}-loadResult.txt"
            ssh ${USER}@${address} -p ${port} "rm -f ${BASE_DIR}/${version}/dbClient${i}-${workload}-runResult.txt"

            i=$[$i+1]
        done
        boxNumber=$[$boxNumber+1]
    done
}

function saveRunInfo {
    version=$1
    jvmsPerBox=$2
    nodesPerJvm=$3
    clientsPerBox=$4
    clientProps=$5
    workload=$6
    outDir=$7

    clusterSize=$[${#CLUSTER_MACHINES[@]}*jvmsPerBox*nodesPerJvm]

    totalProducers=$[${#LOAD_MACHINES[@]}*clientsPerBox]

    scp -P ${port} -q -r ${USER}@${address}:${BASE_DIR}/workloads/${workload} ${outDir}
	scp -P ${port} -q -r ${USER}@${address}:${BASE_DIR}/${clientProps} ${outDir}

	echo "${clusterSize} Node Cluster, over ${#CLUSTER_MACHINES[@]} box ${CLUSTER_MACHINES[@]}, (${jvmsPerBox} Jvm's per box, ${nodesPerJvm} Nodes per Jvm), ${totalProducers} Load producers (over ${#LOAD_MACHINES[@]} box ${LOAD_MACHINES[@]}, ${clientsPerBox} per box)" > ${outDir}/info.txt
}

function combineResults {
    outDir=$1
    version=$2

    java -jar ../processresults/target/processResults-0.1.4.jar "merge" ${outDir}/${version} "runResult"  ${version} > ${outDir}/${version}/temp.csv
    java -jar ../processresults/target/processResults-0.1.4.jar "merge" ${outDir}/${version} "loadResult" ${version} > ${outDir}/${version}/result.csv

    cat ${outDir}/${version}/temp.csv >>  ${outDir}/${version}/result.csv
    rm ${outDir}/${version}/temp.csv
}

function reportResults {
    outDir=$1
    totalInserts=$2
    totalOperations=$3


    java -jar ../processresults/target/processResults-0.1.4.jar "combine" ${outDir} "result" ${totalInserts} ${totalOperations}  > ${outDir}/report.csv 2>${outDir}/errors.txt
}

function createPropertisFile {
    outDir=$1
    fileName=$2

    for box in ${LOAD_MACHINES[@]}
    do
        address=$(address ${box} )
	    port=$( port ${box} )

        ssh ${USER}@${address} -p ${port} "echo 'hazelcastDBClient.nodesPerJVM = ${NODES_PER_DB_CLIENT}
        hazelcastDbClient.clientNodes = ${CLIENT_NODE}
        hazelcastDbClient.clusterIPList = ${CLUSTER_MACHINES[@]}' > ${BASE_DIR}/${fileName}"
    done
}

function killAllJava {

    for box in ${ALL_MACHINES[@]}
    do
        address=$(address ${box} )
	    port=$( port ${box} )

        echo "killing on ${box}"
        ssh ${USER}@${address} -p ${port} "killall -9 java"
    done
}