#!/bin/bash -x
#
# basic, standalone version of report config loader...
#
# parameters can be edited here... (i.e. no need for set-config) 

SERVICE="cspace-services/reports"
CONTENT_TYPE="Content-Type: application/xml"
HOST="xxx.cspace.berkeley.edu"
REPORTURL="http://$HOST:8180"
REPORTUSER="xxx@xxx.cspace.berkeley.edu:xxxx"

if [ $# -ne 3 ]; then
    echo Usage: load-report-basic.sh reportname "report name" "forDocType"
    exit
fi

# put the .jasper file where it belongs, and tell CSpace what to do with it.
if [ -r $1.jasper ];
then
  scp jasper/$1.jasper $HOST:/usr/local/share/apache-tomcat-6.0.33/cspace/reports/
  perl -pe 's/#name#/'"$2"'/g;s/#jasper#/'$1'/g;s/#notes#/'"$4"'/g;s/#doctype#/'"$3"'/g' < reporttemplate.xml  > reportpayload.xml

  curl -X POST $REPORTURL/$SERVICE -i -u "$REPORTUSER" -H "$CONTENT_TYPE" -T reportpayload.xml
else
  echo "$1.jasper -- not found."
fi
