#!/bin/bash -vx

# CSV field locations for barcode 5 fields:
# "Type", "Handler", "Museum number", "New/curr location", "Timestamp for move/inventory"

# 10/24/2012 Now switch to use LocHandler.txt file for "handler" in the barcode file,
#            so slight change in creating /tmp/handler[56].in file & chk_handler variable
#
# 10/25/2012 The DATE-TIME is also passed to this "checkinput_[56]fld.sh" as the 3rd
#      argument, so the intermediate files used for checking are distinguishable
#      among the runs

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh

if [ $# -lt 2 ]; then
    echo "Usage: checkinput_5fld input_filename errlog_filename datetime_stamp"
    exit
fi

INFILE=$1
LOGFILE=$2
TIMESTAMP=$3
echo "" | tee -a $LOGFILE
echo "Checking barcode file $INFILE (no crates) ... "  | tee -a $LOGFILE

echo "$CONNECTSTRING" | tee -a $LOGFILE

nerr=0

# Run a postgres command-line "sql" to get at nuxeo data
# psql returns a table w/ heading and '---' separator, as well as a blank and a 
# "total entry count" lines so need to strip off these before comparing w/ input

# ------ test handler (2nd field) -----
# cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",".*$/$1/' |sort |uniq > /tmp/handler5.in 
# chk_handler=`cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",".*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",.*$/$1/' |sort |uniq | perl ${ROOT_PATH}/handlerid2name.pl ${ROOT_PATH}/LocHandlers.txt | sort > /tmp/handler5.in.${TIMESTAMP}
sleep 3
# echo "handler5.in.${TIMESTAMP} before handler extraction contains the following lines: "
# cat /tmp/handler5.in.${TIMESTAMP}
chk_handler=`cat /tmp/handler5.in.${TIMESTAMP} | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
echo "handler5.in.${TIMESTAMP} contains: $chk_handler"
psql -X -d "$CONNECTSTRING" -c "select pt.termdisplayname from persontermgroup pt where pt.termdisplayname in ($chk_handler);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/handler5.out.${TIMESTAMP}
# echo "handler5.out.${TIMESTAMP} from psql run contains the following lines: "
# cat /tmp/handler5.out.${TIMESTAMP}
comm -13 /tmp/handler5.out.${TIMESTAMP} /tmp/handler5.in.${TIMESTAMP} > /tmp/handler5.missing.${TIMESTAMP}
if [ -s /tmp/handler5.missing.${TIMESTAMP} ]; then
   echo ">> The following HANDLER is NOT in CSpace database:" | tee -a $LOGFILE
   cat /tmp/handler5.missing.${TIMESTAMP} | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi

# ------ test object number (3rd field) -----
cat $INFILE | perl -pe 's/^.*",".*","(.*)",".*",".*$/$1/' |sort |uniq > /tmp/obj5.in.${TIMESTAMP}
chk_obj=`cat $INFILE | perl -pe 's/^.*",".*","(.*)",".*",".*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
# echo $chk_obj
psql -X -d "$CONNECTSTRING" -c "select o.objectnumber from collectionobjects_common o where o.objectnumber in ($chk_obj);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/obj5.out.${TIMESTAMP}
comm -13 /tmp/obj5.out.${TIMESTAMP} /tmp/obj5.in.${TIMESTAMP} > /tmp/obj5.missing.${TIMESTAMP}
if [ -s /tmp/obj5.missing.${TIMESTAMP} ]; then
   echo ">> The following MUSEUM NUMBER is NOT in CSpace database:"  | tee -a $LOGFILE
   cat /tmp/obj5.missing.${TIMESTAMP}  | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi

# ------ test storage location (4th field) -----
cat $INFILE | perl -pe 's/^.*",".*",".*","(.*)",".*$/$1/' |sort |uniq > /tmp/loc5.in.${TIMESTAMP}
chk_loc=`cat $INFILE | perl -pe 's/^.*",".*",".*","(.*)",".*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
# echo $chk_loc
psql -X -d "$CONNECTSTRING" -c "select lt.termdisplayname from loctermgroup lt where lt.termdisplayname in ($chk_loc);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/loc5.out.${TIMESTAMP}
comm -13 /tmp/loc5.out.${TIMESTAMP} /tmp/loc5.in.${TIMESTAMP} > /tmp/loc5.missing.${TIMESTAMP}
if [ -s /tmp/loc5.missing.${TIMESTAMP} ]; then
   echo ">> The following LOCATION is NOT in CSpace database:"  | tee -a $LOGFILE
   cat /tmp/loc5.missing.${TIMESTAMP}  | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi

if [ $nerr -eq 0 ]; then
    echo "No error in barcode file $INFILE (no crates)."  | tee -a $LOGFILE
    exit 0
else
    exit 1
fi
