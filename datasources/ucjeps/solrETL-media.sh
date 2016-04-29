#!/bin/bash -x
date
cd /home/app_solr/solrdatasources/ucjeps
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5310 sslmode=prefer"
USERNAME="reporter_$TENANT"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
export NUMCOLS=55
##############################################################################
# save last night results to tmp just in case
##############################################################################
mv 4solr.${TENANT}.media.csv /tmp
##############################################################################
# get media
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f ucjepsNewMedia.sql -o newmedia.csv
time perl -i -pe 's/[\r\n]/ /g;s/\@\@/\n/g' newmedia.csv
perl -ne 's/\\/x/g; next if / rows/; print $_' newmedia.csv > 4solr.${TENANT}.media.csv
##############################################################################
# clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-media/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# load the csv file into Solr using the csv DIH
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-media/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl -S -s "http://localhost:8983/solr/${TENANT}-media/update/csv?commit=true&header=true&trim=true&separator=%09&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" --data-binary @4solr.$TENANT.media.csv -H 'Content-type:text/plain; charset=utf-8'
# get rid of intermediate files
rm newmedia.csv
# zip up .csvs, save a bit of space on backups
gzip -f *.csv
date
