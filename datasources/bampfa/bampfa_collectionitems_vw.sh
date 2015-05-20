#!/bin/bash -x
#
# script to extract data from the 'special BAMPFA view' and email it to those who need it.
#
date
cd /home/app_solr/solrdatasources/${TENANT}
TENANT=$1
SERVER="dba-postgres-dev-32.ist.berkeley.edu port=5113"
USERNAME="reporter_$TENANT"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
##############################################################################
# 
##############################################################################
time psql -R"@@" -A -U $USERNAME -d "$CONNECTSTRING"  -c "select * from utils.${TENANT}_collectionitems_vw" -o ${TENANT}_collectionitems_vw.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -i -pe 's/[\r\n]/ /g;s/\@\@/\n/g' ${TENANT}_collectionitems_vw.csv 
rm ${TENANT}_collectionitems_vw.csv.gz
gzip ${TENANT}_collectionitems_vw.csv
mail -a ${TENANT}_collectionitems_vw.csv.gz -s "${TENANT}_collectionitems_vw.csv.gz" -- jblowe@berkeley.edu
#
date
