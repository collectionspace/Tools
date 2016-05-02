TENANT=$1
HOSTNAME="dba-postgres-prod-32.ist.berkeley.edu port=$2 sslmode=prefer"
#HOSTNAME="dba-postgres-dev-32.ist.berkeley.edu port=$2 sslmode=prefer"
USERNAME="nuxeo_${TENANT}"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$HOSTNAME dbname=$DATABASE password=xxxx"
psql -e -a -U $USERNAME -d "$CONNECTSTRING" -f $3
