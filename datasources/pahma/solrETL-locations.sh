#!/bin/bash -x
#
##############################################################################
# shell script to extract multiple tabular data files from CSpace,
# "stitch" them together (see join.py)
# prep them for load into Solr4 using the "csv datahandler"
##############################################################################
date
cd /home/app_solr/solrdatasources/pahma
TENANT=$1
HOSTNAME="dba-postgres-prod-32.ist.berkeley.edu port=5307 sslmode=prefer"
export NUMCOLS=36
USERNAME="reporter_pahma"
DATABASE="pahma_domain_pahma"
CONNECTSTRING="host=$HOSTNAME dbname=$DATABASE"
##############################################################################
# extract media info from CSpace
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f locations1.sql -o m1.csv
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f locations2.sql -o m2.csv
# cleanup newlines and crlf in data, then switch record separator.
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m1.csv > m1a.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m2.csv > m2a.csv
rm m1.csv m2.csv
##############################################################################
# stitch the two files together
##############################################################################
time sort m1a.csv > m1a.sort.csv &
time sort m2a.csv > m2a.sort.csv &
wait
rm m1a.csv m2a.csv
time join -j 1 -t $'\t' m1a.sort.csv m2a.sort.csv > m3.sort.csv
rm m1a.sort.csv m2a.sort.csv
cut -f1-5,10-14 m3.sort.csv > m4.csv
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
grep csid m4.csv > header4Solr.csv
grep -v csid m4.csv > m5.csv
cat header4Solr.csv m5.csv > m4.csv
rm m5.csv
time perl -ne " \$x = \$_ ;s/[^\t]//g; if (length eq 8) { print \$x;}" m4.csv > 4solr.${TENANT}.locations.csv
rm m4.csv
date
