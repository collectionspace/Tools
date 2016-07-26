LOCKFILE=/tmp/tricoderlock
SUBJECT="Tricoder Batch Script is locked out on `hostname`"
EMAIL="pahma-tricoder@lists.berkeley.edu,cspace-support@lists.berkeley.edu"

if mkdir $LOCKFILE; then
  echo "Locking succeeded" >&2
  /home/app_webapps/batch_barcode/import_barcode_typeR.sh &> /home/app_webapps/batch_barcode/log/all_barcode_typeR.msg
  rm -rf $LOCKFILE
else
  echo "Lock failed - exit" >&2
  echo "Please investigate. This is not necessarily an error, but no batches will run until the lock is cleared." | /bin/mail -s "${SUBJECT}" "${EMAIL}"
  exit 1
fi
