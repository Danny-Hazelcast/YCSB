#!/bin/bash
. functions.sh

OUTPUT_DIR="results"

downLoadResults ${VERSION} ${DB_CLIENTS_PER_BOX} ${WORKLOAD} ${OUTPUT_DIR}

combineResults ${OUTPUT_DIR}/${VERSION} runResult
combineResults ${OUTPUT_DIR}/${VERSION} loadResult


killAllJava