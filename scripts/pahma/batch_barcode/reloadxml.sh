#!/bin/bash
# reloadxml.sh from csimport.sh, modified to reload tricoder XML files that failed
# timeout set to 900 for Tricoder imports
# URL and USER vars set by reading setBarcodeEnv.sh

if [ $# -ne 1 ]; then
    echo "Usage: csimport900 XML-filename"
    exit
fi

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh

m=`date +"%m"`
d=`date +"%d"`
y=`date +"%Y"`
FILENAME=$(basename $1)
LOGFILE=curl_log.$FILENAME.$y$m$d
DATA=$1

echo "Sending $DATA to $URL, filename is $FILENAME"

attempts=0
while [ $attempts -le 2 ]
do
    curl -s -i -u "$USER" ${URL}?impTimout=900 -X POST -H "$CONTENT_TYPE" -T $DA
TA -o "curl.out.$FILENAME.$y$m$d"
    if grep -q "Unable to commit/rollback" curl.out.$FILENAME.$y$m$d
    then
        echo "commit error detected; retrying $FILENAME ---" >> $LOGFILE
        attempts=$(( $attempts + 1 ))
    else
        # assume succcess, or other unrecoverable error; bail out.
        attempts=10
    fi
done
# Count number of import records read by "curl" and append to a log file.
echo "Counting $DATA " `grep READ curl.out.$FILENAME.$y$m$d | wc -l` >> $LOGFILE
grep READ curl.out.$FILENAME.$y$m$d | wc -l
