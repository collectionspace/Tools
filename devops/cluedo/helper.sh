#!/bin/bash

if [ $# -ne 3 ]; then
    echo Usage:
    echo $0 COMMAND AUTHORITY RECORDTYPE
    echo e.g.
    echo nohup time $0 delete 49d792ea-585b-4d38-b591 personauthorities &
    exit
fi

COMMAND=$1
USER=$CSPACEUSER
AUTHORITY=$2
URL=$URL
SERVICE="cspace-services/$3"

echo COMMAND=$COMMAND
echo AUTHORITY=$2
echo URL=$URL
echo SERVICE="cspace-services/$3"

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
	    echo "curl -S --stderr - -X DELETE $URL/$SERVICE$ITEMS/$CSID --basic -u \"$USER\" -H \"$CONTENT_TYPE\""
	    curl -S --stderr - -X DELETE $URL/$SERVICE$ITEMS/$CSID --basic -u "$USER" -H "$CONTENT_TYPE" > /dev/null
	done
    ;;

    'list')
	echo "listing..."
	XMLFILE=curl.items
	rm -f $XMLFILE
	
	for count in {0..1}
	do
	    echo "curl -S --stderr curl.junk -X \"GET $URL/$SERVICE$ITEMS?pgSz=1000&pgNum=$count\" --basic -u \"$USER\" -H \"$CONTENT_TYPE\"" >> $LOG
	    curl -S --stderr curl.${count}.items -X GET "$URL/$SERVICE$ITEMS?pgSz=1000&pgNum=$count" --basic -u "$USER" -H "$CONTENT_TYPE" >> $XMLFILE
	done
     ;;

    'load')
	
    ;;
esac
