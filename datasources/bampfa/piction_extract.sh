#!/bin/bash -x
#
# script to extract data from the 'piction materialzied view' and email it to those who need it.
#
date
TENANT=$1
cd /home/app_solr/solrdatasources/${TENANT}
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5415 sslmode=prefer"
USERNAME="piction"
DATABASE="piction_transit"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
##############################################################################
# 
##############################################################################
#time psql -A -d "host=dba-postgres-prod-42.ist.berkeley.edu dbname=piction_transit port=5415 sslmode=prefer" -U "piction"  -c "select * from piction.bampfa_metadata_mv" -o ${TENANT}_pictionview_vw.tab
time psql -R"@@" -A -U $USERNAME -d "$CONNECTSTRING"  -c "select * from piction.bampfa_metadata_mv" -o ${TENANT}_pictionview_vw.tab
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -i -pe 's/[\r\n]/ /g;s/\@\@/\n/g;s/\|/\t/g;' ${TENANT}_pictionview_vw.tab
rm ${TENANT}_pictionview_vw.tab.gz
gzip ${TENANT}_pictionview_vw.tab
mail -a ${TENANT}_pictionview_vw.tab.gz -s "${TENANT}_pictionview_vw.csv.gz" -- cspace-piction-view@lists.berkeley.edu < /dev/null
#
date
