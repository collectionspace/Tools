#!/bin/bash
#
# "install" report (i.e. create a record in cspace for the report.)
# don't forget to put the report .jrxml in the cspace reports directory on the target server!
#
# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(stat -f $0)
# Absolute path this script is in. /home/user/bin
SCRIPTPATH=`dirname $SCRIPT`

SERVICE="cspace-services/reports"
CONTENT_TYPE="Content-Type: application/xml"

if [ "$REPORTURL" == "" ] || [ "$REPORTUSER" == "" ]; then
    echo "REPORTURL and/or REPORTUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi


if [ $# -ne 4 ]; then
    echo "Usage: load-report.sh reportname \"report name\" \"forDocType\" \"note\""
    echo
    echo "NB: for values which can be blank, use \"\" as a placeholder"
    echo "    reportname is the filename, without extension of the JRXML file you have placed/will place"
    echo "    in the reports directory, (e.g. myreport, not myreport.jrxml)"
    exit
fi

#if [ -r $1.jrxml ];
if true;
then
  #sudo cp $1.jrxml /usr/local/share/apache-tomcat-6.0.33/cspace/reports/
  perl -pe 's/#name#/'"$2"'/g;s/#jrxml#/'$1'/g;s/#notes#/'"$4"'/g;s/#doctype#/'"$3"'/g' < $SCRIPTPATH/reporttemplate.xml  > tempreportpayload.xml

  #echo curl -X POST $REPORTURL/$SERVICE -i -u "$REPORTUSER" -H "$CONTENT_TYPE" -T tempreportpayload.xml
  curl -X POST $REPORTURL/$SERVICE -i -u "$REPORTUSER" -H "$CONTENT_TYPE" -T tempreportpayload.xml
  #rm tempreportpayload.xml
else
  echo "$1.jrxml -- not found."
fi
