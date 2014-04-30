#!/bin/bash
. functions.sh

zipCurrentDir "ycsb.zip"

for box in ${ALL_MACHINES[@]}
do
	install $box "ycsb.zip"
done

rm -f "ycsb.zip"