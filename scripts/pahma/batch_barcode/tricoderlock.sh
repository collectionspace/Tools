LOCKFILE=/tmp/tricoderlock
SUBJECT="Tricoder Batch Script still running on `hostname`"
EMAIL="pahma-tricoder@lists.berkeley.edu,cspace-support@lists.berkeley.edu"

if mkdir $LOCKFILE; then
  echo "Locking succeeded" >&2
  /home/app_webapps/batch_barcode/import_barcode_typeR.sh &> /home/app_webapps/batch_barcode/log/all_barcode_typeR.msg
  rm -rf $LOCKFILE
else
  echo "Lock failed - exit" >&2
  echo " The Tricoder Batch script tried to run but found an existing lock. This situation should clear up by itself but if it persists, please notify RIT staff." | /bin/mail -s "${SUBJECT}" "${EMAIL}"
  exit 1
fi
