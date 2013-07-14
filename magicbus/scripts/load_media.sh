#!/bin/bash

# for SEQ in {0..0}; do
# for SEQ in {1..38}; do
# for SEQ in {10..20}; do
# for SEQ in {10..10}; do
for SEQ in {31..38}; do
    echo "Processing madia file #${SEQ} --------------------"
	time ./runmedia.v2 2012-09-15 ${SEQ} pahma_done 2012-09-13 media
done
