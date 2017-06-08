#!/bin/bash

# CSV field locations for barcode 6 fields (w/ crate):
# "Type", "Handler", "Timestamp for move/inventory", "Museum number", "crate, "New/curr location"

# Need to escape single quote for the shell for perl -e to deal with single quote ---
# perl -e 'print "greengrocer'\''s\n"' will print greengrocer's

# 10/24/2012 Now switch to use LocHandler.txt file for "handler" in the barcode file,
#            so slight change in creating /tmp/handler[56].in file & chk_handler variable
#
# 10/25/2012 The DATE-TIME is also passed to this "checkinput_[56]fld.sh" as the 3rd
#      argument, so the intermediate files used for checking are distinguishable
#      among the runs

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh

if [ $# -lt 2 ]; then
    echo "Usage: checkinput_6fld input_filename errlog_filename datetime_stamp"
    exit
fi

INFILE=$1
LOGFILE=$2
TIMESTAMP=$3

echo "" | tee -a $LOGFILE
echo "Checking barcode file $INFILE (has crates) ... "  | tee -a $LOGFILE

echo "$CONNECTSTRING" | tee -a $LOGFILE

nerr=0

# Run a postgres command-line "sql" to get at nuxeo data
# psql returns a table w/ heading and '---' separator, as well as a blank and a 
# "total entry count" lines so need to strip off these before comparing w/ input

# ------ test handler (2nd field) -----
# cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",".*",.*$/$1/' |sort |uniq > /tmp/handler6.in 
# chk_handler=`cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",".*",.*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `

cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",".*",.*$/$1/' |sort |uniq | perl ${ROOT_PATH}/handlerid2name.pl ${ROOT_PATH}/LocHandlers.txt |sort > /tmp/handler6.in.${TIMESTAMP}
sleep 3
# echo "handler6.in.${TIMESTAMP} before handler extraction contains the following lines: "
# cat /tmp/handler6.in.${TIMESTAMP}
chk_handler=`cat /tmp/handler6.in.${TIMESTAMP} | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
# echo "handler6.in.${TIMESTAMP} contains: $chk_handler"
psql -X -d "$CONNECTSTRING" -c "select pt.termdisplayname from persontermgroup pt where pt.termdisplayname in ($chk_handler);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/handler6.out.${TIMESTAMP}
# echo "handler6.out.${TIMESTAMP} from psql run contains: $chk_handler"
# sleep 3
comm -13 /tmp/handler6.out.${TIMESTAMP} /tmp/handler6.in.${TIMESTAMP} > /tmp/handler6.missing.${TIMESTAMP}
if [ -s /tmp/handler6.missing.${TIMESTAMP} ]; then
   echo ">> The following HANDLER is NOT in CSpace database:" | tee -a $LOGFILE
   cat /tmp/handler6.missing.${TIMESTAMP} | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi

# ------ test object number (4th field) -----
cat $INFILE | perl -pe 's/^.*",".*",".*","(.*)",".*",.*$/$1/' |sort |uniq > /tmp/obj6.in.${TIMESTAMP}
chk_obj=`cat $INFILE | perl -pe 's/^.*",".*",".*","(.*)",".*",.*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
# echo $chk_obj
psql -X -d "$CONNECTSTRING" -c "select o.objectnumber from collectionobjects_common o where o.objectnumber in ($chk_obj);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/obj6.out.${TIMESTAMP}
comm -13 /tmp/obj6.out.${TIMESTAMP} /tmp/obj6.in.${TIMESTAMP} > /tmp/obj6.missing.${TIMESTAMP}
if [ -s /tmp/obj6.missing.${TIMESTAMP} ]; then
   echo ">> The following MUSEUM NUMBER is NOT in CSpace database:" | tee -a $LOGFILE
   cat /tmp/obj6.missing.${TIMESTAMP} | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi

# ------ test crate (5th field) -----
cat $INFILE | perl -pe 's/^.*",".*",".*",".*","(.*)",.*$/$1/' |sort |uniq > /tmp/crate6.in.${TIMESTAMP}
chk_crate=`cat $INFILE | perl -pe 's/^.*",".*",".*",".*","(.*)",.*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
# echo $chk_crate
psql -X -d "$CONNECTSTRING" -c "select lt.termdisplayname from loctermgroup lt inner join hierarchy h1 on (lt.id=h1.id) left outer join locations_common l on (h1.parentid=l.id) where l.inauthority='e8069316-30bf-4cb9-b41d' and lt.termdisplayname in ($chk_crate);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/crate6.out.${TIMESTAMP}
comm -13 /tmp/crate6.out.${TIMESTAMP} /tmp/crate6.in.${TIMESTAMP} > /tmp/crate6.missing.${TIMESTAMP}
if [ -s /tmp/crate6.missing.${TIMESTAMP} ]; then
   echo ">> The following CRATE is NOT in CSpace database:" | tee -a $LOGFILE
   cat /tmp/crate6.missing.${TIMESTAMP} | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi

# ------ test storage location (6th field) -----
# Somehow perl cannot parse the LAST field the same way as the others
# because of the ^M character as part of new line, --- strip that first
cat $INFILE | tr -d '\15' | perl -pe 's/^.*",".*",".*",".*",".*","(.*)"$/$1/' |sort |uniq > /tmp/loc6.in.${TIMESTAMP}
chk_loc=`cat $INFILE | tr -d '\15' | perl -pe 's/^.*",".*",".*",".*",".*","(.*)"$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
# echo $chk_loc
psql -X -d "$CONNECTSTRING" -c "select lt.termdisplayname from loctermgroup lt inner join hierarchy h1 on (lt.id=h1.id) left outer join locations_common l on (h1.parentid=l.id) where l.inauthority='d65c614a-e70e-441b-8855' and lt.termdisplayname in ($chk_loc);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/loc6.out.${TIMESTAMP}
comm -13 /tmp/loc6.out.${TIMESTAMP} /tmp/loc6.in.${TIMESTAMP} > /tmp/loc6.missing.${TIMESTAMP}
if [ -s /tmp/loc6.missing.${TIMESTAMP} ]; then
   echo ">> The following LOCATION is NOT in CSpace database:" | tee -a $LOGFILE
   cat /tmp/loc6.missing.${TIMESTAMP} | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi

if [ $nerr -eq 0 ]; then
    echo "No error in barcode file $INFILE (contains crates)." | tee -a $LOGFILE
    exit 0
else
    exit 1
fi
