#!/bin/bash

# Meed to run the sequence 1 through 9 separately, so the "cleanup"  
# doesn't zip up the 1x to 9x (2-digit sequence) XML files.

# for SEQ in {0..0}; do
# for SEQ in {1..9}; do
# for SEQ in {10..20}; do
#    echo "Processing MH-obj file #${SEQ} --------------------"
#        time ./runrelation_MHobj.v3 2012-09-15 ${SEQ} pahma_done_MHobj 
# done

# for SEQ in {31..99}; do
for SEQ in {100..126}; do
     echo "Processing MH-obj file #${SEQ} --------------------"
         time ./runrelation_MHobj.v3 2012-09-15 ${SEQ} pahma_done_MHobj 
done
