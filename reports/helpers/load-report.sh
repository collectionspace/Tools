#!/bin/bash
#
# "install" report (i.e. create a record in cspace for the report.
# don't forget to put the report .jrxml in the cspace reports directory!

SERVICE="cspace-services/reports"
CONTENT_TYPE="Content-Type: application/xml"

if [ "$REPORTURL" == "" ] || [ "$REPORTUSER" == "" ]; then
    echo "REPORTURL and/or REPORTUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi


if [ $# -ne 4 ]; then
    echo "Usage: load-report.sh reportname \"report name\" \"forDocType\" \"note\""
    exit
fi

if [ -r $1.jrxml ];
then
  #sudo cp $1.jrxml /usr/local/share/apache-tomcat-6.0.33/cspace/reports/
  perl -pe 's/#name#/'"$2"'/g;s/#jrxml#/'$1'/g;s/#notes#/'"$4"'/g;s/#doctype#/'"$3"'/g' < reporttemplate.xml  > tempreportpayload.xml

  #echo curl -X POST $REPORTURL/$SERVICE -i -u "$REPORTUSER" -H "$CONTENT_TYPE" -T tempreportpayload.xml
  curl -X POST $REPORTURL/$SERVICE -i -u "$REPORTUSER" -H "$CONTENT_TYPE" -T tempreportpayload.xml
  #rm tempreportpayload.xml
else
  echo "$1.jrxml -- not found."
fi
