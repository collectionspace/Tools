#!/bin/bash
#
#
if [ "$REPORTURL" == "" ] || [ "$REPORTUSER" == "" ]; then
    echo "REPORTURL and/or REPORTUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

curl -s -S --basic -u "$REPORTUSER" -X GET -H "Content-Type:application/xml" $REPORTURL/cspace-services/reports/$1 | xmllint --format -
