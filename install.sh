#!/bin/bash
. functions.sh

zipCurrentDir "ycsb.zip"

for machine in $MACHINES
do
	install $machine "ycsb.zip"
done

rm -f "ycsb.zip"