#!/bin/bash

SERVICE="cspace-services/$1"
CONTENT_TYPE="Content-Type: application/xml"
CSID=$2

if [ "$CSPACEURL" == "" ] || [ "$CSPACEUSER" == "" ]; then
    echo "CSPACEURL and/or CSPACEUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

if [ $# -ne 2 ]; then
    echo "Usage: delete-single.sh service csid"
    exit
fi

echo "curl -X DELETE $CSPACEURL/$SERVICE/$CSID -u \"$CSPACEUSER\" -H \"$CONTENT_TYPE\""
# exit on error (so we don't print the "deleted" message)
set -e
curl -X DELETE $CSPACEURL/$SERVICE/$CSID -u "$CSPACEUSER" -H "$CONTENT_TYPE"
echo $1 $CSID deleted
