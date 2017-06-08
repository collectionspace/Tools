#!/bin/bash -x
#
# script to extract data from the 'special BAMPFA view' and email it to those who need it.
#
date
TENANT=$1
cd /home/app_solr/solrdatasources/${TENANT}
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5313 sslmode=prefer"
USERNAME="reporter_$TENANT"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
##############################################################################
# 
##############################################################################
time psql -R"@@" -A -U $USERNAME -d "$CONNECTSTRING"  -c "select * from utils.${TENANT}_collectionitems_vw" -o ${TENANT}_collectionitems_vw.tab
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -i -pe 's/[\r\n]/ /g;s/\@\@/\n/g;s/\|/\t/g;' ${TENANT}_collectionitems_vw.tab
rm ${TENANT}_collectionitems_vw.tab.gz
gzip ${TENANT}_collectionitems_vw.tab
mail -a ${TENANT}_collectionitems_vw.tab.gz -s "${TENANT}_collectionitems_vw.csv.gz" -- osanchez@berkeley.edu < /dev/null
#
date
