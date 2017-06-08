#!/bin/bash

if [ -s /tmp/loc6.missing.2013-02-08-100001 ]; then
   echo ">> The following LOCATION is NOT in CSpace database:" 
   cat /tmp/loc6.missing.2013-02-08-100001
fi
