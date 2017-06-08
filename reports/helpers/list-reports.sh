#!/bin/bash
#
#
if [ "$REPORTURL" == "" ] || [ "$REPORTUSER" == "" ]; then
    echo "REPORTURL and/or REPORTUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

curl -i -S --stderr - --basic -u "$REPORTUSER" -X GET -H "Content-Type:application/xml" $REPORTURL/cspace-services/reports/ > curl.items
perl -pe 's/<list/\n<list/g' curl.items | perl -ne 'while (s/<list\-item>.*?<csid>(.*?)<.*?<name>(.*?)<.*?<\/list\-item>//) { print "$1\t$2\n" }' 
rm curl.items
