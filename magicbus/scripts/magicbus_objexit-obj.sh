#!/bin/bash

# for SEQ in {0..0}; do
for SEQ in {1..4}; do
     echo "Processing objexit-obj file #${SEQ} --------------------"
         time ./runrelation_objexit-obj.v3 2012-10-10 ${SEQ} pahma_done
done
