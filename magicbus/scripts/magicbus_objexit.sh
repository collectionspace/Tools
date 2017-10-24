#!/bin/bash

# for SEQ in {0..0}; do
for SEQ in {1..4}; do
    echo "Processing objexit file #${SEQ} --------------------"
	time ./run_objexit.v2 2012-10-10 ${SEQ} pahma_done 2012-10-10 objexit
done
