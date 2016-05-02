#!/bin/bash

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh

del_hierarchyCSID=`cat /tmp/todel_hierarchy_allCSID | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' | tr -d "\\n"  | sed -e "s/,$//" `

psql -X -d "$CONNECTSTRING" -c "select * from hierarchy where name in ($del_hierarchyCSID);" | tee -a /tmp/todel_select
psql -X -d "$CONNECTSTRING" -c "delete from hierarchy where name in ($del_hierarchyCSID);" | tee -a /tmp/todel_select
