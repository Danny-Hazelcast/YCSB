#!/bin/bash
. functions.sh

#tailClusterOutput ${VERSION} ${CLUSTER_JVMS_PER_BOX}

temp=("a" "b" "c" "d")

l=${#temp[@]}


echo $l


for i in  ${temp[@]}
 do
   echo $i
 done