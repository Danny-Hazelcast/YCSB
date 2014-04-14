#!/bin/bash
. functions.sh


runTransactionPhase ${VERSION} ${DB_CLIENTS_PER_BOX} ${WORKLOAD} "2client.properties"