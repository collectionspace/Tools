#!/bin/bash -x
#
##############################################################################
# shell script to extract osteology data from database and prep them for load
# into Solr4 using the "csv datahandler"
##############################################################################
date
cd /home/app_solr/solrdatasources/pahma
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
HOSTNAME="dba-postgres-prod-42.ist.berkeley.edu port=5307 sslmode=prefer"
USERNAME="reporter_pahma"
DATABASE="pahma_domain_pahma"
CONNECTSTRING="host=$HOSTNAME dbname=$DATABASE"
export NUMCOLS=68
##############################################################################
# extract media info from CSpace
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f osteology.sql -o o1.csv
# cleanup newlines and crlf in data, then switch record separator.
time perl -i -pe 's/[\r\n]/ /g;s/\@\@/\n/g' o1.csv
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
gunzip 4solr.${TENANT}.internal.csv.gz
# dunno why this is happening, but somehow this file contains a line with like 200,000 commas in it.
perl -i -ne 'print unless length > 30000' 4solr.pahma.internal.csv
# compress the osteology data into a single variable
python osteology_analyzer.py o1.csv o2.csv
sort o2.csv > o1.csv
# add the internal data
python join.py o1.csv 4solr.${TENANT}.internal.csv > o2.csv
# csid_s is both files, let's keep only one in this file
cut -f1,3- o2.csv > o1.csv
grep csid o1.csv > header4Solr.csv
grep -v csid o1.csv > o2.csv
cat header4Solr.csv o2.csv > o1.csv
rm o2.csv
time perl -ne " \$x = \$_ ;s/[^\t]//g; if     (length eq \$ENV{NUMCOLS}) { print \$x;}" o1.csv | perl -pe 's/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;' > 4solr.pahma.osteology.csv &
time perl -ne " \$x = \$_ ;s/[^\t]//g; unless (length eq \$ENV{NUMCOLS}) { print \$x;}" o1.csv | perl -pe 's/\\/\//g' > errors.osteology.csv &
wait
# hack to fix inventorydate_dt
perl -i -pe 's/([\d\-]+) ([\d:]+)/\1T\2Z/' 4solr.${TENANT}.osteology.csv
# ok, now let's load this into solr...
# clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-osteology/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-osteology/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# this POSTs the csv to the Solr / update endpoint
# note, among other things, the overriding of the encapsulator with \
##############################################################################
time curl -S -s "http://localhost:8983/solr/${TENANT}-osteology/update/csv?commit=true&header=true&separator=%09&f.aggregate_ss.split=true&f.aggregate_ss.separator=,&f.objaltnum_ss.split=true&f.objaltnum_ss.separator=%7C&f.objfilecode_ss.split=true&f.objfilecode_ss.separator=%7C&f.objdimensions_ss.split=true&f.objdimensions_ss.separator=%7C&f.objmaterials_ss.split=true&f.objmaterials_ss.separator=%7C&f.objinscrtext_ss.split=true&f.objinscrtext_ss.separator=%7C&f.objcollector_ss.split=true&f.objcollector_ss.separator=%7C&f.objaccno_ss.split=true&f.objaccno_ss.separator=%7C&f.objaccdate_ss.split=true&f.objaccdate_ss.separator=%7C&f.objacqdate_ss.split=true&f.objacqdate_ss.separator=%7C&f.objassoccult_ss.split=true&f.objassoccult_ss.separator=%7C&f.objculturetree_ss.split=true&f.objculturetree_ss.separator=%7C&f.exhibitionnumber_ss.split=true&f.exhibitionnumber_ss.separator=%7C&f.exhibitiontitle_ss.split=true&f.exhibitiontitle_ss.separator=%7C&f.grouptitle_ss.split=true&f.grouptitle_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" --data-binary @4solr.${TENANT}.osteology.csv -H 'Content-type:text/plain; charset=utf-8'
rm o1.csv o3.csv header4Solr.csv
gzip -f 4solr.${TENANT}.osteology.csv
gzip -f 4solr.${TENANT}.internal.csv
date
