#!/bin/bash

SERVICE="cspace-services/reports"
CONTENT_TYPE="Content-Type: application/xml"
CSID=$1

if [ "$REPORTURL" == "" ] || [ "$REPORTUSER" == "" ]; then
    echo "REPORTURL and/or REPORTUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

if [ $# -ne 1 ]; then
    echo "Usage: delete-report.sh reportcsid"
    exit
fi

echo "curl -X DELETE $REPORTURL/$SERVICE/$CSID -u \"$REPORTUSER\" -H \"$CONTENT_TYPE\""
# exit on error (so we don't print the "report deleted" message)
set -e
curl -X DELETE $REPORTURL/$SERVICE/$CSID -u "$REPORTUSER" -H "$CONTENT_TYPE"
echo report $CSID deleted
