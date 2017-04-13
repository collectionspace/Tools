#!/bin/bash
#
export HOSTNAME="localhost:8180"
export CSPACEURL="$HOSTNAME"
export URL="$CSPACEURL"

export CONTENT_TYPE="Content-Type: application/xml"
export LOGIN="admin@core.collectionspace.org"
export PASSWORD="Administrator"
export CSPACEUSER="$LOGIN:$PASSWORD"

echo
echo ">>>>> Environment variables set:"
echo CSPACEURL  $CSPACEURL
echo CSPACEUSER $CSPACEUSER
echo
