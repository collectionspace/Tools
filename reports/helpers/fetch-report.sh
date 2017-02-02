#!/bin/bash
#
#
if [ "$REPORTURL" == "" ] || [ "$REPORTUSER" == "" ]; then
    echo "REPORTURL and/or REPORTUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

if [ $# -ne 3 ]; then
    echo "Usage: fetch-report.sh reportcsid itemcsid doctype"
    echo
    echo "e.g. ./fetch-report.sh f45de201-3429-4d67-a1b2 ebf5f72f-65ab-499f-ac47-4fa9b720a6d3 CollectionObject > aReport.pdf"
    echo
    echo "NB: only works for reports with a doctype."
    exit
fi

perl -pe 's/#csid#/'"$2"'/g;s/#doctype#/'"$3"'/g' < payload.xml  > tempreportpayload.xml

#echo curl -X POST $REPORTURL/$SERVICE -i -u "$REPORTUSER" -H "$CONTENT_TYPE" -T tempreportpayload.xml
curl -X POST $REPORTURL/cspace-services/reports/$1 -i -u "$REPORTUSER" -H "$CONTENT_TYPE" -T tempreportpayload.xml
