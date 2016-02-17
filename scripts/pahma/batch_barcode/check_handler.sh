#!/bin/bash

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh

handler_name=`cat LocHandlers.nameonly | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' | tr -d "\\n"  | sed -e "s/,$//" `

echo
echo Count of names: `wc -l LocHandlers.nameonly`
echo Count of names: `wc -l LocHandlers.txt`
sort LocHandlers.nameonly > /tmp/handler.nameonly
psql -t -A -X -d "$CONNECTSTRING" -c "select pt.termdisplayname from persontermgroup pt where pt.termdisplayname in ($handler_name) order by pt.termdisplayname;" | sort -u >  /tmp/handler.out
echo
echo "===========================                                     =========================="
echo "Batch Handler List                                              CSpace User List"
echo "===========================                                     =========================="
diff -y /tmp/handler.nameonly /tmp/handler.out
#rm /tmp/handler.out /tmp/handler.nameonly
