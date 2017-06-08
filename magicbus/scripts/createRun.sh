#!/bin/bash -x
cp zipbatches/$3.$1-$2.zip .
unzip zipbatches/$3.$1-$2.zip
for  (( i=$1; i<=$2; i++ ))
do
   echo ./runrel.v3 2012-06-26 $i pahmaMOrel 2012-06-26 $3
done
