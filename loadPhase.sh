#!/bin/bash
. functions.sh


runLoadPhase ${VERSION} ${DB_CLIENTS_PER_BOX} ${WORKLOAD} "2client.properties" ${PUTS_PER_DB_CLIENT}