#!/bin/bash
#
if [ "$CSPACEURL" == "" ] || [ "$CSPACEUSER" == "" ]; then
    echo "CSPACEURL and/or CSPACEUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

if [ $# -ne 2 ]; then
    echo Usage: delete-multiple.sh service listofcsids.csv
    exit
fi

if [ -r $2 ];
then
  for item in  `cut -f1 $2` ; do ./delete-single.sh $1 $item ; done 
else
  echo "$2 -- list of csids not found."
fi

