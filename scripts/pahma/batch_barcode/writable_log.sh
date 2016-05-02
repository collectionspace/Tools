#!/bin/bash

# this script is not used any more
exit 0

m=`date '+%m'`  # init to today's month/day/year
d=`date '+%d'`
y=`date '+%Y'`
DATE=${y}-${m}-${d}
ROOT_PATH=${ROOT_PATH}
LOGFILE=${ROOT_PATH}/log/Barcode_log.$y$m$d
chmod 664 $LOGFILE

