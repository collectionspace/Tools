#!/bin/bash -x
#
# Clean up/out existing authority:
#
cut -f1 $1 | ./helper.sh delete "$LOGIN:$PASSWORD" "" "$URL" $2
