#!/bin/bash
#
export HOSTNAME="xxx.cspace.berkeley.edu"
export CSPACEURL="https://$HOSTNAME"
export URL="$CSPACEURL"

export CONTENT_TYPE="Content-Type: application/xml"
export LOGIN="xxx@xxx.cspace.berkeley.edu"
export PASSWORD="password"
export CSPACEUSER="$LOGIN:$PASSWORD"

echo
echo ">>>>> Environment variables set:"
echo CSPACEURL  $CSPACEURL
echo CSPACEUSER $CSPACEUSER
echo
