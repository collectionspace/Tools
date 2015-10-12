#!/bin/bash

COMMAND=$1
USER=$2
AUTHORITY=$3
URL=$4
SERVICE="cspace-services/$5"

echo COMMAND=$1
echo USER=$2
echo AUTHORITY=$3
echo URL=$4
echo SERVICE="cspace-services/$5"

CONTENT_TYPE="Content-Type: application/xml"
HTTP="HTTP/1.1"

#AUTHORITY="63678593-e69a-4e36-99e9"
#URL="http://localhost:8180"
#USER="admin@pahma.cspace.berkeley.edu:Administrator"

LOG=log.$COMMAND
rm -f $LOG

if [ "$AUTHORITY" = "" ]; then
    ITEMS=""
else
    ITEMS="/$AUTHORITY/items"
fi

case "$COMMAND" in
    'delete')
	echo "deleting..."
	rm -f curl.delete
	count=0
	
	while read CSID
        do
	    echo "${count}: curl -S --stderr - -X DELETE $URL/$SERVICE$ITEMS/$CSID --basic -u \"$USER\" -H \"$CONTENT_TYPE\"" >> $LOG
	    curl -S --stderr - -X DELETE $URL/$SERVICE$ITEMS/$CSID --basic -u "$USER" -H "$CONTENT_TYPE" >> curl.delete
	done
    ;;

    'list')
	echo "listing..."
	XMLFILE=curl.items
	rm -f $XMLFILE
	
	for count in {0..1}
	do
	    echo "${count}: curl -S --stderr curl.junk -X \"GET $URL/$SERVICE$ITEMS?pgSz=1000&pgNum=$count\" --basic -u \"$USER\" -H \"$CONTENT_TYPE\"" >> $LOG
	    curl -S --stderr curl.${count}.items -X GET "$URL/$SERVICE$ITEMS?pgSz=1000&pgNum=$count" --basic -u "$USER" -H "$CONTENT_TYPE" >> $XMLFILE
	done
     ;;

    'load')
	
    ;;
esac
