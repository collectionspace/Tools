#!/bin/bash -x
#
# list some authority records...
#
#
AUTHORITY=$1
CSID=$2

if [ "$CSPACEURL" == "" ] || [ "$CSPACEUSER" == "" ]; then
    echo "CSPACEURL and/or CSPACEUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

#
# Make a csv file of certain values for an authority
#
./helper.sh list "$LOGIN:$PASSWORD" "$CSID" "$URL" $AUTHORITY
perl -pe 's/<list/\n<list/g' curl.items | perl -ne 'while (s/<list\-item>.*?<csid>(.*?)<.*?<(termDisplayName|refName)>(.*?)<.*?<(termDisplayName|refName)>(.*?)<.*?<\/list\-item>//) { print "$1\t$3\t$5\n" }' > $HOSTNAME.$AUTHORITY.$CSID.items
