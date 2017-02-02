#!/bin/bash

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh

nerr=0
TIMESTAMP=$1
NOCRATE=$2

# check if missing 5-fields, 6-fields & mvCrate files, and create empty ones
# to avoid "No such file or directory" error message
if [ ! -e "/tmp/handler5.in.${TIMESTAMP}" ]; then
    touch /tmp/handler5.in.${TIMESTAMP}
    touch /tmp/obj5.in.${TIMESTAMP}
    touch /tmp/loc5.in.${TIMESTAMP}
fi
if [ ! -e "/tmp/handler6.in.${TIMESTAMP}" ]; then
    touch /tmp/handler6.in.${TIMESTAMP}
    touch /tmp/obj6.in.${TIMESTAMP}
    touch /tmp/loc6.in.${TIMESTAMP}
    touch /tmp/crate6.in.${TIMESTAMP}
fi
if [ ! -e "/tmp/handler_mvCrate.in.${TIMESTAMP}" ]; then
    touch /tmp/handler_mvCrate.in.${TIMESTAMP}
    touch /tmp/crate_mvCrate.in.${TIMESTAMP}
    touch /tmp/newLoc_mvCrate.in.${TIMESTAMP}
fi

# Run a postgres command-line "sql" to get at nuxeo data

# ------ handler (person authority: shortID, CSID, refname) -----
all_handler=`cat /tmp/handler5.in.${TIMESTAMP} /tmp/handler6.in.${TIMESTAMP} /tmp/handler_mvCrate.in.${TIMESTAMP} | tr -d '\15' |sort |uniq | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' | tr -d "\\n"  | sed -e "s/,$//" `
# echo $all_handler
psql -X -d "$CONNECTSTRING" -c " select p.shortidentifier shortID, h2.name CSID, p.refname refname from persontermgroup pt inner join hierarchy h1 on (pt.id=h1.id) left outer join persons_common p on (h1.parentid=p.id) left outer join hierarchy h2 on (p.id=h2.id) left outer join misc on (p.id=misc.id) where misc.lifecyclestate <> 'deleted' and pt.termdisplayname in ($all_handler)" | sed -e '$d' | sed -e '$d' | perl ${ROOT_PATH}/reformat.pl > /tmp/all_handler.tab.${TIMESTAMP}

# ------ object number (nuxeo_ID, CSID, objectNum, objectID) -----
all_obj=`cat /tmp/obj5.in.${TIMESTAMP} /tmp/obj6.in.${TIMESTAMP} | tr -d '\15' |sort |uniq | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' | tr -d "\\n"  | sed -e "s/,$//" `
# echo $all_obj
# If the barcode scanned file contains only the "R" (move crate) type,
# then skip next SQL call & not produce /tmp/all_obj.tab.${TIMESTAMP}; 
# But ther will be /tmp/all_crateObj.tab.{$TIMESTAMP} from 
# "checkinput_mvCrate_typeR.sh" run earlier.
# NOTE: must quote the variable when testing w/ -z (variable may contain space that
#       throws off the test).
if [ ! -z "$all_obj" ]; then
    psql -X -d "$CONNECTSTRING" -c "select h.id, h.name, o.objectnumber, p.pahmaobjectid from hierarchy h, collectionobjects_common o, collectionobjects_pahma p, misc m where o.id=h.id and o.id=m.id  and o.id=p.id and m.lifecyclestate <> 'deleted' and o.objectnumber in ($all_obj)" | sed -e '$d' | sed -e '$d' | perl ${ROOT_PATH}/reformat.pl > /tmp/all_obj.tab.${TIMESTAMP}
fi

# ------ storage location (displayName, termName, termStatus, shortID, refName) -----
all_loc=`cat /tmp/loc5.in.${TIMESTAMP} /tmp/loc6.in.${TIMESTAMP} /tmp/newLoc_mvCrate.in.${TIMESTAMP} | tr -d '\15' |sort |uniq | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' | tr -d "\\n"  | sed -e "s/,$//" `
# echo $all_loc
psql -X -d "$CONNECTSTRING" -c "select lt.termdisplayname, lt.termname, lt.termstatus, l.shortidentifier, l.refname from loctermgroup lt inner join hierarchy h1 on (lt.id=h1.id) left outer join locations_common l on (h1.parentid=l.id) left outer join misc on (l.id=misc.id) where l.inauthority='d65c614a-e70e-441b-8855' and misc.lifecyclestate <> 'deleted' and lt.termdisplayname in ($all_loc);"  | sed -e '$d' | sed -e '$d' | perl ${ROOT_PATH}/reformat.pl > /tmp/all_loc.tab.${TIMESTAMP}

# ------ crate (displayName, termName, termStatus, shortID, refName) -----
# don't do SQL pull if no file w/ crates
if [ $NOCRATE -eq 0 ]; then
    all_crate=`cat /tmp/crate6.in.${TIMESTAMP} /tmp/crate_mvCrate.in.${TIMESTAMP} | tr -d '\15' |sort |uniq | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' | tr -d "\\n"  | sed -e "s/,$//" `
    # echo $all_crate
    psql -X -d "$CONNECTSTRING" -c "select lt.termdisplayname, lt.termname, lt.termstatus, l.shortidentifier, l.refname from loctermgroup lt inner join hierarchy h1 on (lt.id=h1.id) left outer join locations_common l on (h1.parentid=l.id) left outer join misc on (l.id=misc.id) where l.inauthority='e8069316-30bf-4cb9-b41d' and misc.lifecyclestate <> 'deleted' and lt.termdisplayname in ($all_crate);"  | sed -e '$d' | sed -e '$d' | perl ${ROOT_PATH}/reformat.pl > /tmp/all_crate.tab.${TIMESTAMP}
fi
