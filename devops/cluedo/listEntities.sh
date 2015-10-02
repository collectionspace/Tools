#!/bin/bash -x
#
# list non-authority CSpace entities (object, procedures).
#
#
if [ "$CSPACEURL" == "" ] || [ "$CSPACEUSER" == "" ]; then
    echo "CSPACEURL and/or CSPACEUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

ENTITIES=$1
EXTRACT=$2
#
# Make a csv file of certain values for an authority
#
./helper.sh list "$LOGIN:$PASSWORD" "" "$URL" $ENTITIES
perl -pe 's/<list/\n<list/g' curl.items | perl -ne 'while (s/<list\-item>.*?<csid>(.*?)<.*?<$ENV{EXTRACT}.*?>(.*?)<.*?<\/list\-item>//) { print "$2\t$1\n" }' | sort > $HOSTNAME.$ENTITIES.items
