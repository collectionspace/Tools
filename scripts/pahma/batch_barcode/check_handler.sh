#!/bin/bash

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh

handler_name=`cut -f2 LocHandlers.txt | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' | tr -d "\\n"  | sed -e "s/,$//" `

echo
echo Count of lines: `wc -l LocHandlers.txt`
cut -f2 LocHandlers.txt | sort -u > /tmp/handler.nameonly
psql -t -A -X -d "$CONNECTSTRING" -c "select pt.termdisplayname from persontermgroup pt where pt.termdisplayname in ($handler_name) order by pt.termdisplayname;" | sort -u >  /tmp/handler.out
echo
echo "===========================                                     =========================="
echo "Batch Handler List                                              CSpace User List"
echo "===========================                                     =========================="
diff -y /tmp/handler.nameonly /tmp/handler.out
rm /tmp/handler.out /tmp/handler.nameonly
