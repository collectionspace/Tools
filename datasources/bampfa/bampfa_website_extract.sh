#!/bin/bash -x
#
# script to extract data for the BAMPFA website and email it to those who need it.
#
date
TENANT=$1
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5313 sslmode=prefer"
USERNAME="reporter_$TENANT"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
##############################################################################
# 
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING"  -f bampfa_website_extract.sql -o bwe.tab
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g;' bwe.tab | perl addStatus.pl 26 |  cut -f1-26,29- > ${TENANT}_website_objects_extract.tab
cut -f4-10 ${TENANT}_website_objects_extract.tab | sort | uniq > artist.extract
grep    nationality artist.extract > artist.header
grep -v nationality artist.extract > artist.tmp
cat artist.header artist.tmp > ${TENANT}_website_artists_extract.tab
# BAMPFA-351 CRH
grep objectcsid ${TENANT}_website_objects_extract.tab > objhdr.tsv
awk -v oldest=`date --date="7 days ago" +%Y-%m-%d` -F'\t' '(NR>1) && ($28 > oldest)' ${TENANT}_website_objects_extract.tab > 7day.tsv
awk -v oldest=`date --date="30 days ago" +%Y-%m-%d` -F'\t' '(NR>1) && ($28 > oldest)' ${TENANT}_website_objects_extract.tab > 30day.tsv
cat objhdr.tsv 7day.tsv > ${TENANT}_website_objects_extract_7day.tab
cat objhdr.tsv 30day.tsv > ${TENANT}_website_objects_extract_30day.tab 
#
wc ${TENANT}_website_*_extract*.tab
cp ${TENANT}_website_*_extract*.tab /var/www/static
echo "https://webapps.cspace.berkeley.edu/${TENANT}_website_objects_extract.tab" | mail -s "new ${TENANT} website extract available" -- aharris@berkeley.edu
#rm ${TENANT}_website_*_extract.tab.gz
#gzip ${TENANT}_website_*_extract.tab
#mail -a ${TENANT}_website_objects_extract.tab.gz -a ${TENANT}_website_artists_extract.tab.gz -s "${TENANT} website extract `date`" -- jblowe@berkeley.edu < /dev/null
rm bwe.tab artist.header artist.tmp artist.extract objhdr.tsv 7day.tsv 30day.tsv
#
date

