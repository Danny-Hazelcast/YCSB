#!/bin/bash
. functions.sh


OUTPUT_DIR="report"


#reportResults ${OUTPUT_DIR}


CLUSTER_MACHINES=("${BOX2}")
LOAD_MACHINES=("${BOX3}")

ALL=${CLUSTER_MACHINES[*]}" "${LOAD_MACHINES[*]}

 for a in ${ALL[@]}
 do

 echo $a

 done
