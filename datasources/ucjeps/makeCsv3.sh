#!/bin/bash -x
date
cd /home/developers/ucjeps
TENANT=$1
HOSTNAME=$TENANT.cspace.berkeley.edu
PASSWORD=$2
export NUMFIELDS=28
USERNAME="reporter_ucjeps"
DATABASE="ucjeps_domain_ucjeps"
CONNECTSTRING="host=$HOSTNAME dbname=$DATABASE password=$PASSWORD"
##############################################################################
# extract metadata (dead and alive) info from CSpace
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f ucjepsMetadataV2.sql -o d1.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1.csv > d3.csv 
time perl -ne '$x = $_ ;s/[^\t]//g; if (length eq 41) { print $x;} '     d3.csv > d4.csv
time perl -ne '$x = $_ ;s/[^\t]//g; unless (length eq 41) { print $x;} ' d3.csv > errors.csv &
mv d4.csv metadata.csv
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING"-f ucjepsMediaV1.sql -o m1.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m1.csv > media.csv
rm m1.csv d1.csv d3.csv
# add the blobcsids to the rest of the data
time perl mergeObjectsAndMedia.pl > d6.csv
# we want to use our "special" solr-friendly header.
tail -n +2 d6.csv | perl fixdate.pl > d7.csv
cat metadataHeaderV3.csv d7.csv > 4solr.$TENANT.metadata.csv
rm d6.csv d7.csv m1.csv d1.csv d3.csv
wc -l *.csv
# clear out the existing data
curl "http://localhost:8983/solr/${TENANT}-metadata/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl "http://localhost:8983/solr/${TENANT}-metadata/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl "http://localhost:8983/solr/${TENANT}-metadata/update/csv?commit=true&header=true&trim=true&separator=%09&f.previousdeterminations_ss.split=true&f.previousdeterminations_ss.separator=;&f.associatedtaxa_ss.split=true&f.associatedtaxa_ss.separator=;&f.typeassertions_ss.split=true&f.typeassertions_ss.separator=;&f.othernumbers_ss.split=true&f.othernumbers_ss.separator=;&f.blobs_ss.split=true&f.blobs_ss.separator=,&encapsulator=\\" --data-binary @4solr.$TENANT.metadata.csv -H 'Content-type:text/plain; charset=utf-8'
#
rm 4solr*.csv.gz
gzip 4solr.*.csv
#
date
