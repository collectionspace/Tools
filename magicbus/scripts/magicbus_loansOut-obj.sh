#!/bin/bash

for SEQ in {0..1}; do
     echo "Processing loanOut-obj file #${SEQ} --------------------"
         time ./runrelation_loansOut-obj.v3 2012-10-10 ${SEQ} pahma_done
done
