#!/bin/bash -x
date
time du -sh $1
time df -h
time find $1  -name "*" -type f | wc -l
date
