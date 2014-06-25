#!/bin/bash -x
date
#cd /home/developers/pahma
HOST=$1
# extract media info from CSpace
time psql -F $'\t' -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f media.sql -o m1.csv
# cleanup newlines and crlf in data, then switch record separator.
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m1.csv > 4solr.$HOST.media.csv
rm m1.csv
#
time psql -F $'\t' -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f basic.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > basic.csv
cp basic.csv intermediate.csv
#
for i in {1..17}
do
 time psql -F $'\t' -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f part$i.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > part$i.csv
 time python join.py intermediate.csv part$i.csv > temp.csv
 cp temp.csv intermediate.csv
done
rm temp.csv
time perl -ne '$x = $_ ;s/[^\t]//g; if (length eq 36) { print $x;} ' intermediate.csv | perl -pe 's/\"/\\"/g;' > 4solr.$HOST.metadata.csv
time perl -ne '$x = $_ ;s/[^\t]//g; unless (length eq 36) { print $x;} ' intermediate.csv | perl -pe 's/\"/\\"/g;' > errors.csv
rm intermediate.csv
#
# add the blobcsids to the rest of the data
time perl mergeObjectsAndMedia.pl 4solr.$HOST.media.csv 4solr.$HOST.metadata.csv > d6.csv
# we want to use our "special" solr-friendly header.
#tail -n +2 d6.csv > d7.csv
cat header4Solr.csv d6.csv | perl -pe 's/␥/|/g' > 4solr.$HOST.metadata.csv
rm d6.csv
# rm d7.csv
wc -l *.csv
# clear out the existing data
curl "http://localhost:8983/solr/pahma-metadata/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl "http://localhost:8983/solr/pahma-metadata/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
# load the data into solr using the csv datahandler
#
time curl 'http://localhost:8983/solr/pahma-metadata/update/csv?commit=true&header=true&separator=%09&f.objfilecode_ss.split=true&f.objfilecode_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,' --data-binary @4solr.$HOST.metadata.csv -H 'Content-type:text/plain; charset=utf-8'
# wrap things up: make a gzipped version of what was loaded
rm 4solr*.csv.gz
gzip 4solr.*.csv
date
