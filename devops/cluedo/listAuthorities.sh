#!/bin/bash
#
# list some authority records...
#
#

if [ "$CSPACEURL" == "" ] || [ "$CSPACEUSER" == "" ]; then
    echo "CSPACEURL and/or CSPACEUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

#
# Make a csv file of all the authorities
#
for AUTHORITY in locationauthorities personauthorities placeauthorities conceptauthorities taxonauthories
do
  ./helper.sh list "$LOGIN:$PASSWORD" "" "$CSPACEURL" $AUTHORITY
  cat curl*.items | perl -pe 's/<list/\n<list/g' | perl -ne 'while (s/<list\-item>.*?<uri>(.*?)<.*?<(termDisplayName|refName)>(.*?)<.*?<\/list\-item>//) { print "$1\t$3\n" }' > $HOSTNAME.$AUTHORITY.items
#cat curl*.items > $HOSTNAME.$AUTHORITY.curl.items
done
