#!/bin/bash -x 
#
# Create Procedure records
#

if [ "$CSPACEURL" == "" ] || [ "$CSPACEUSER" == "" ]; then
    echo "CSPACEURL and/or CSPACEUSER environment variables are not set. Did you edit set-config.sh and 'source set-config.sh'?"
    exit
fi
if [ $# -ne 4 ]; then
    echo Usage:
    echo ./loadEntities INPUTFILE XMLTEMPLATEFILE ENTITY MODE
    echo e.g.
    echo nohup time ./loadEntities.sh movements2load.csv minMovement.xml movement MOVEMENTS1 &
    exit
fi

INPUTFILE=$1
XMLFILE=$2
ENTITY=$3
MODE=$4

perl post2CSpace.pl $CSPACEURL $LOGIN $PASSWORD "" ${ENTITY}s $XMLFILE $INPUTFILE > $MODE.load$ENTITY.report.txt

#./helper.sh list "$LOGIN:$PASSWORD" "" "$CSPACEURL" ${ENTITY}s
#
#FIELDS="termDisplayName|refName"
#if [ "$ENTITY" == "movement" ] ; then
#    FIELDS="currentLocation|movementReferenceNumber"
#fi

#perl -pe 's/<list/\n<list/g' curl.items | perl -ne 'while (s/<list\-item>.*?<csid>(.*?)<.*?<(termDisplayName|refName)>(.*?)<.*?<(termDisplayName|refName)>(.*?)<.*?<\/list\-item>//) { print "$1\t$3\t$5\n" }' > $MODE.$ENTITY.items
#
#curl -i -S --stderr - --basic -u $LOGIN:$PASSWORD -X GET -H "Content-Type:application/xml" $CSPACEURL/cspace-services/${ENTITY}s | perl -ne 's/<totalItems>(\d+)<\/totalItems>// && (print "$1 $ENTITY\n")'


