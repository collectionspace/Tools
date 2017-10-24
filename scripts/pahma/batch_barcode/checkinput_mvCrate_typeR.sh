#!/bin/bash

# 7/18/2013 Per Jira PAHMA-843, Michael added the "R" type to the
#             TriCoder scanner w/ the following 5-fileds format:
#     1. "R": Type of activity (box move)
#     2. Handler code 
#     3. Timestamp
#     4. Box name
#     5. New location name

# Need to escape single quote for the shell for perl -e to deal with single quote ---
# perl -e 'print "greengrocer'\''s\n"' will print greengrocer's

# 10/24/2012 Now switch to use LocHandler.txt file for "handler" in the barcode file,
#            so slight change in creating /tmp/handler_mvCrate.in file & chk_handler variable
#
# 10/25/2012 The DATE-TIME is also passed to this "checkinput__mvCrate.sh" as the 3rd
#      argument, so the intermediate files used for checking are distinguishable
#      among the runs

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh

if [ $# -ne 3 ]; then
    echo "Usage: checkinput_mvCrate_typeR input_filename errlog_filename datetime_stamp"
    exit
fi

echo "connect: $CONNECTSTRING"

# Script assume only the special move crate lines (i.e. "R" lines) will be in the file
INFILE=$1
LOGFILE=$2
TIMESTAMP=$3

echo "" | tee -a $LOGFILE
echo "Checking barcode file $INFILE (moving crates) ... "  | tee -a $LOGFILE

nerr=0
ROOT_PATH=`pwd`

# Run a postgres command-line "sql" to get at nuxeo data
# psql returns a table w/ heading and '---' separator, as well as a blank and a 
# "total entry count" lines so need to strip off these before comparing w/ input

# ------ test handler (2nd field) -----
# cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",.*$/$1/' |sort |uniq > /tmp/handler_mvCrate.in 
# chk_handler=`cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",.*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `

cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",.*$/$1/' |sort |uniq | perl ${ROOT_PATH}/handlerid2name.pl ${ROOT_PATH}/LocHandlers.txt |sort > /tmp/handler_mvCrate.in.${TIMESTAMP}
sleep 3
# echo "handler_mvCrate.in.${TIMESTAMP} before handler extraction contains the following lines: "
# cat /tmp/handler_mvCrate.in.${TIMESTAMP}
chk_handler=`cat /tmp/handler_mvCrate.in.${TIMESTAMP} | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
# echo "handler_mvCrate.in.${TIMESTAMP} contains: $chk_handler"
psql -X -d "$CONNECTSTRING" -c "select pt.termdisplayname from persontermgroup pt where pt.termdisplayname in ($chk_handler);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/handler_mvCrate.out.${TIMESTAMP}
# echo "handler_mvCrate.out.${TIMESTAMP} from psql run contains: $chk_handler"
# sleep 3
comm -13 /tmp/handler_mvCrate.out.${TIMESTAMP} /tmp/handler_mvCrate.in.${TIMESTAMP} > /tmp/handler_mvCrate.missing.${TIMESTAMP}
if [ -s /tmp/handler_mvCrate.missing.${TIMESTAMP} ]; then
   echo ">> The following HANDLER is NOT in CSpace database:" | tee -a $LOGFILE
   cat /tmp/handler_mvCrate.missing.${TIMESTAMP} | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi

# ------ test crate (4th field) -----
cat $INFILE | perl -pe 's/^.*",".*",".*","(.*)",.*$/$1/' |sort |uniq > /tmp/crate_mvCrate.in.${TIMESTAMP}
chk_crate=`cat $INFILE | perl -pe 's/^.*",".*",".*","(.*)",.*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
# echo $chk_crate
psql -X -d "$CONNECTSTRING" -c "select lt.termdisplayname from loctermgroup lt inner join hierarchy h1 on (lt.id=h1.id) left outer join locations_common l on (h1.parentid=l.id) where l.inauthority='e8069316-30bf-4cb9-b41d' and lt.termdisplayname in ($chk_crate);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/crate_mvCrate.out.${TIMESTAMP}
comm -13 /tmp/crate_mvCrate.out.${TIMESTAMP} /tmp/crate_mvCrate.in.${TIMESTAMP} > /tmp/crate_mvCrate.missing.${TIMESTAMP}
if [ -s /tmp/crate_mvCrate.missing.${TIMESTAMP} ]; then
   echo ">> The following CRATE is NOT in CSpace database:" | tee -a $LOGFILE
   cat /tmp/crate_mvCrate.missing.${TIMESTAMP} | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi

# ------ test FUTURE storage location (5th field) -----
# Somehow perl cannot parse the LAST field the same way as the others
# because of the ^M character as part of new line, --- strip that first
cat $INFILE | tr -d '\15' | perl -pe 's/^.*",".*",".*",".*","(.*)"$/$1/' |sort |uniq > /tmp/newLoc_mvCrate.in.${TIMESTAMP}
chk_newLoc=`cat $INFILE | tr -d '\15' | perl -pe 's/^.*",".*",".*",".*","(.*)"$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
# echo $chk_newLoc
psql -X -d "$CONNECTSTRING" -c "select lt.termdisplayname from loctermgroup lt inner join hierarchy h1 on (lt.id=h1.id) left outer join locations_common l on (h1.parentid=l.id) where l.inauthority='d65c614a-e70e-441b-8855' and lt.termdisplayname in ($chk_newLoc);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/newLoc_mvCrate.out.${TIMESTAMP}
comm -13 /tmp/newLoc_mvCrate.out.${TIMESTAMP} /tmp/newLoc_mvCrate.in.${TIMESTAMP} > /tmp/newLoc_mvCrate.missing.${TIMESTAMP}
if [ -s /tmp/newLoc_mvCrate.missing.${TIMESTAMP} ]; then
   echo ">> The following NEW LOCATION is NOT in CSpace database:" | tee -a $LOGFILE
   cat /tmp/newLoc_mvCrate.missing.${TIMESTAMP} | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi

# ------ GET ALL object numbers that are currently in the crate/loc -----
# will produce a tab-delimited file:/tmp/multiObj.tab
# ${ROOT_PATH}/findObject_inCrate_typeR.sh ${INFILE} ${TIMESTAMP}
 

if [ $nerr -eq 0 ]; then
    echo "No error in barcode file $INFILE (crate move)." | tee -a $LOGFILE
    exit 0
else
    exit 1
fi
