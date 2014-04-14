#!/bin/bash
. functions.sh

OUTPUT_DIR="result"

downLoadResults ${VERSION} ${DB_CLIENTS_PER_BOX} ${WORKLOAD} $OUTPUT_DIR

killAllJava