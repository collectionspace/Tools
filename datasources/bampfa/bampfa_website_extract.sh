#!/bin/bash -x
#
# script to extract data for the BAMPFA website and email it to those who need it.
#
date
TENANT=$1
cd /home/app_solr/solrdatasources/${TENANT}
SERVER="dba-postgres-prod-32.ist.berkeley.edu port=5313 sslmode=prefer"
USERNAME="reporter_$TENANT"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
##############################################################################
# 
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING"  -f bampfa_website_extract.sql -o bwe.tab
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g;' bwe.tab | time perl addStatus.pl 27 |  cut -f1-27,30- > ${TENANT}_website_objects_extract.tab
cut -f4-10 ${TENANT}_website_objects_extract.tab | sort | uniq > artist.extract
grep    nationality artist.extract > artist.header
grep -v nationality artist.extract > artist.tmp
cat artist.header artist.tmp > ${TENANT}_website_artists_extract.tab
wc ${TENANT}_website_*_extract.tab
rm ${TENANT}_website_*_extract.tab.gz
gzip ${TENANT}_website_*_extract.tab
mail -a ${TENANT}_website_objects_extract.tab.gz -a ${TENANT}_website_artists_extract.tab.gz -s "${TENANT} website extract `date`" -- jblowe@berkeley.edu < /dev/null
rm bwe.tab artist.header artist.tmp artist.extract
#
date
