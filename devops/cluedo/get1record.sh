#!/bin/bash

if [ "$CSPACEURL" == "" ] || [ "$CSPACEUSER" == "" ]; then
    echo "CSPACEURL and/or CSPACEUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

if [ $# -eq 0 ]; then
    echo
    echo "Gets the first record of the specified type and tries to 'templatize' it."
    echo
    echo "Usage: $0 <recordtype> <optional-authority-csid>"
    echo "e.g. : $0 personauthorities "
    exit
fi


SERVICE="cspace-services/$1"
AUTHORITY=$2

#echo SERVICE="cspace-services/$1"
#echo AUTHORITY=$2

CONTENT_TYPE="Content-Type: application/xml"
HTTP="HTTP/1.1"

if [ "$AUTHORITY" = "" ]; then
    ITEMS=""
else
    ITEMS="/$AUTHORITY/items"
fi

#echo "curl -S --stderr curl.junk -X \"GET $CSPACEURL/$SERVICE$ITEMS?pgSz=1000&pgNum=$count\" --basic -u \"$CSPACEUSER\" -H \"$CONTENT_TYPE\"" >> $LOG
curl -S --stderr curl2.tmp -X GET "$CSPACEURL/$SERVICE$ITEMS?pgSz=1" --basic -u "$CSPACEUSER" -H "$CONTENT_TYPE" >> curl.tmp
perl -pe 's/<list/\n<list/g' curl.tmp | perl -ne 'while (s/<list\-item>.*?<csid>(.*?)<.*?<$ENV{EXTRACT}.*?>(.*?)<.*?<\/list\-item>//) { print "$1\n" }' >> csid.tmp
CSID=`cat csid.tmp`
curl -S --stderr curl.junk -X GET "$CSPACEURL/$SERVICE/$CSID" --basic -u "$CSPACEUSER" -H "$CONTENT_TYPE" > $1.tmp
xmllint --format $1.tmp | perl -pe 's/<(\w+)>.*?<\//<\1>#\1#<\//' > $1.template.xml
xmllint --format $1.tmp > $1.xml
rm -f curl.tmp curl.junk curl2.tmp csid.tmp $1.tmp


