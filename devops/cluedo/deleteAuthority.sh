#!/bin/bash -x
#
# Clean up/out existing authority:
#
echo Cleaning out $URL/$AUTHORITY/$CSID using file $1
cut -f1 $1 | ./helper.sh delete "$LOGIN:$PASSWORD" "$2" "$3" "$4"
