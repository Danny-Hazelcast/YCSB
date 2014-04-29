#!/bin/bash
. functions.sh

GG="gridgain"
DB_CLIENTS_PER_BOX=8


tailDbClientOutput ${GG} ${DB_CLIENTS_PER_BOX}