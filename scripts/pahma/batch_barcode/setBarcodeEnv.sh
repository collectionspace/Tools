
#set verbose

# target server
export URL="https://pahma-dev.cspace.berkeley.edu/cspace-services/imports"
export USER="xxxx@pahma.cspace.berkeley.edu:xxxxxx"
export CONTENT_TYPE="Content-Type: application/xml"

# password comes from .pgpass
export CONNECTSTRING="host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma "

# setup for email
export SUBJECT="Importing barcode LMI (C/M/R types)"
export EMAIL="jblowe@berkeley.edu"

export ROOT_PATH=/home/app_webapps/batch_barcode
export UPLOAD_PATH=${ROOT_PATH}/input
#EMAIL3="pahma-tricoder@lists.berkeley.edu"

