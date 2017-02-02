#!/bin/bash

# 1. Reading pre-processed crate locations from the previous step 
#    ("checkinput_mvCrate_typeR.sh") which created the verified list
#    inside filename: "/tmp/crate_mvCrate.out.[date-timestamp]"
# 2. Attempt to search the collection objects matching computed-crate 
#    with the given crate on each line
# 3. Return a tab-delimited file containing list of ---
#    objectNumber, crate_refname (current crate), loc_refname (current location)
#
# Usage example: ./findObject_inVerifiedCrate_typeR.sh testcrate 2013-02-04-232140
#
# NOTE: TO PREVENT "read" tripping off extra blanks (space or tab beyond 1),
# must use IFS= (nothing) before the "read" AND use double-quote in echo

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh

# create blank timestamped output file first 
INFILE=$1
TIMESTAMP=$2

# echo TIMESTAMP IS ${TIMESTAMP}
echo -n "" > /tmp/all_crateObj.tab.${TIMESTAMP}

while IFS= read currline; 
do

   # --------- crate name (refname) ----------------
   # produce single-quoted String to be used in later SQL
   currcrate=`echo "$currline" | perl -pe 's/^(.*)$/''\'\''$1''\'\''/' | tr -d "\\n" `
   psql -X -d "$CONNECTSTRING" -c "select refname from locations_common l join hierarchy h1 on (l.inauthority='e8069316-30bf-4cb9-b41d' and l.id=h1.id) join hierarchy h2 on h1.id=h2.parentid join loctermgroup lt on lt.id=h2.id where lt.termdisplayname=${currcrate} and h2.pos=0;" |awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' > /tmp/onecrate
   # produce Dollar-quoted String to be used in later SQL
   currcrate_refname=`cat /tmp/onecrate | sed -e 's/^/$$/' | sed -e 's/$/$$/' `
   echo ${currcrate_refname}

   # NOT appending anything to the SQL output (the "findObject_inCrate_typeR.sh" did)
   # the tab-delimited filename is TIMESTAMP'd 
   psql -X -d "$CONNECTSTRING" -c "select h.id, h.name, o.objectnumber, p.pahmaobjectid, oa.computedcrate, o.computedcurrentlocation from hierarchy h, collectionobjects_common o, collectionobjects_pahma p, collectionobjects_anthropology oa, misc m where o.id=h.id and o.id=m.id and o.id=oa.id and o.id=p.id and m.lifecyclestate <> 'deleted' and oa.computedcrate=${currcrate_refname};" | awk '{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' > /tmp/multiObj
   if [ -s /tmp/multiObj ]; then
      cat /tmp/multiObj | perl ${ROOT_PATH}/reformat.pl >> /tmp/all_crateObj.tab.${TIMESTAMP}
   fi

done < $INFILE
