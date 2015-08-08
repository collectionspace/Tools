#!/bin/bash

# DATA=import.xml
if [ $# -lt 3 ]; then
    echo "Usage: csimport user@server:password https://server XML-filename"
    exit
fi

URL="$2/cspace-services/imports"
CONTENT_TYPE="Content-Type: application/xml"
USER="$1"

m=`date +"%m"`
d=`date +"%d"`
y=`date +"%Y"`
LOGFILE=curl_log.${FILENAME}.$y$m$d
FILENAME=$(basename $3)

n=0
while [ $# -gt 0 ]; do
    DATA=$3
    echo "Sending $DATA to $URL"

    attempts=0
    while [ $attempts -le 2 ]
    do
        curl -s -i -u "$USER" ${URL}?impTimout=600 -X POST -H "$CONTENT_TYPE" -T $DATA -o curl.out.${FILENAME}.$y$m$d
        if grep -q "Unable to commit/rollback" curl.out.${FILENAME}.$y$m$d
        then
            echo "commit error detected; retrying ${FILENAME} ---" >> $LOGFILE
            attempts=$(( $attempts + 1 ))
        else
            # assume succcess, or other unrecoverable error; bail out.
            attempts=10
        fi
    done
    # Cout number of import records read by "curl" and append to a log file.
    echo "Counting $DATA ---" >> $LOGFILE
    grep READ curl.out.${DATA} | wc -l >> $LOGFILE

    shift
    n=`expr $n + 1`

#   mv $DATA ${DATA}.done

done
echo "$n file(s) processed"
