#!/bin/bash

MACHINE1='192.168.2.101'
MACHINE2='192.168.2.102'
MACHINE3='192.168.2.103'
MACHINE4='192.168.2.104'
MACHINES="${MACHINE1} ${MACHINE2} ${MACHINE3} ${MACHINE4}"
USER=danny

TARGET_DIR=ycsbtmp

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
	ADDRESS=$( address ${MACHINE} )
	PORT=$( port ${MACHINE} )

    ZIP_NAME=$2

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


zipCurrentDir "ycsb.zip"

for machine in $MACHINES
do
	install $machine "ycsb.zip"
done