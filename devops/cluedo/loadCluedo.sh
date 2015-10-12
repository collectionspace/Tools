#!/bin/bash -x 
####
echo Loading Cluedo Museum...
date
# AUTHORITYINPUT PREFIX AUTHORITY CSID TEMPLATE CSPACEURL LOGIN PASSWORD
time ./loadAuthority.sh persons.csv  PERSONS personauthorities "$CSID" xml/persons.xml "$CSPACEURL" "$LOGIN" "$PASSWORD"
time ./loadAuthority.sh storagelocations.csv  LOCATIONS locationauthorities "$CSID" xml/locationsWithoutShortID.xml "$CSPACEURL" "$LOGIN" "$PASSWORD"
time ./loadAuthority.sh materials.csv  MATERIALS conceptauthorites "$CSID" xml/materials.xml "$CSPACEURL" "$LOGIN" "$PASSWORD"

time ./loadEntities.sh collectionobjects.csv  OBJECTS collectionobjects xml/collectionobjects.xml "$CSPACEURL" "$LOGIN" "$PASSWORD"
time ./loadEntities.sh media.csv  MEDIA media xml/media.xml "$CSPACEURL" "$LOGIN" "$PASSWORD"
time ./loadEntities.sh movements.csv  MOVEMENTS movements xml/minMovements.xml "$CSPACEURL" "$LOGIN" "$PASSWORD"

time ./loadRelations.sh media2objects.csv  MEDIA2OBJECTS "$AUTHORITY" "$CSID" xml/media2objects.xml "$CSPACEURL" "$LOGIN" "$PASSWORD"
time ./loadRelations.sh movements2objects.csv  OBJECTS2LOCATIONS "$AUTHORITY" "$CSID" xml/movements2objects.xml "$CSPACEURL" "$LOGIN" "$PASSWORD"

date

