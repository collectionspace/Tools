#!/bin/bash
#
if [ "$REPORTURL" == "" ] || [ "$REPORTUSER" == "" ]; then
    echo "REPORTURL and/or REPORTUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

if [ $# -ne 1 ]; then
    echo Usage: delete-all-reports.sh listofreports.csv
    exit
fi

if [ -r $1 ];
then
  for report in  `cut -f1 $1` ; do ./delete-report.sh $report ; done 
else
  echo "$1 -- list of reports not found."
fi

