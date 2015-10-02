#!/bin/bash -x
#
# load some authority records...
#
#
AUTHORITYINPUT=$1
MODE=$2
AUTHORITY=$3
CSID=$4
TEMPLATE=$5
CSPACEURL=$6
LOGIN=$7
PASSWORD=$8

wc -l $AUTHORITYINPUT

if [ "$CSPACEURL" == "" ] || [ "$CSPACEUSER" == "" ]; then
    echo "CSPACEURL and/or CSPACEUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi

if [ "$MODE" == "" ] ; then
    echo "$MODE is not set, setting it to PRODUCTION for this run"
    MODE="PRODUCTION"
    exit
fi

#
# Load authority records:
#
perl post2CSpace.pl "$CSPACEURL" "$LOGIN" "$PASSWORD" "$CSID" "$AUTHORITY" "$TEMPLATE.xml" "$AUTHORITYINPUT" > $MODE.load.$TEMPLATE.report.txt
grep "Location:" $MODE.load.$TEMPLATE.report.txt | perl -pe "s/^Location: +//" > $MODE.load.$TEMPLATE.urls
wc -l $MODE.load*.urls
#
# 5. Create list of termDisplayNames, refNames & CSIDs:
#
./helper.sh list "$LOGIN:$PASSWORD" "$CSID" "$URL" $AUTHORITY
perl -pe 's/<list/\n<list/g' curl.items | perl -ne 'while (s/<list\-item>.*?<csid>(.*?)<.*?<(termDisplayName|refName)>(.*?)<.*?<(termDisplayName|refName)>(.*?)<.*?<\/list\-item>//) { print "$1\t$3\t$5\n" }' > $MODE.$AUTHORITY.items
#
curl -i -S --stderr - --basic -u $LOGIN:$PASSWORD -X GET -H "Content-Type:application/xml" $URL/cspace-services/$AUTHORITY/$CSID/items | perl -ne 's/<totalItems>(\d+)<\/totalItems>// && (print "$1 $AUTHORITY\n")'
#
