#!/bin/bash
. functions.sh

zipCurrentDir "ycsb.zip"

for box in ${MACHINES[@]}
do
	install $box "ycsb.zip"
done

rm -f "ycsb.zip"