#!/bin/bash -x
cp zipbatches/move$1-$2.zip .
unzip zipbatches/move$1-$2.zip
for  (( i=$1; i<=$2; i++ ))
do
   time ./runset.v2 2012-06-26 $i pahma_done 2012-06-26 move
done
