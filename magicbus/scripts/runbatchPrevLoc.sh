#!/bin/bash -x
cp zipbatch/$3.$1-$2.zip .
unzip $3.$1-$2.zip
for  (( i=$1; i<=$2; i++ ))
do
   time ./runset.v2 2012-06-29 $i $4 $3 2012-06-29 move
done
