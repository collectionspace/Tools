#!/bin/bash -x
date
cd /home/developers/ucjeps
HOST=$1
# extract metadata and media info from CSpace
time psql -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f ucjepsMetadataV1.sql -o d1.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1.csv > d3.csv 
time perl -ne '$x = $_ ;s/[^\|]//g; if (length eq 23) { print $x;} '     d3.csv | perl -pe 's/\"/\\"/g;' > d4.csv
time perl -ne '$x = $_ ;s/[^\|]//g; unless (length eq 23) { print $x;} ' d3.csv | perl -pe 's/\"/\\"/g;' > errors.csv &
mv d4.csv metadata.csv
time psql -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f ucjepsMediaV1.sql -o m1.csv 
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m1.csv > media.csv 
rm m1.csv d1.csv d3.csv
# add the blobcsids to the rest of the data
time perl mergeObjectsAndMedia.pl > d6.csv
# we want to use our "special" solr-friendly header.
tail -n +2 d6.csv | perl fixdate.pl > d7.csv
cat metadataHeaderV1.csv d7.csv > 4solr.$HOST.metatadata.csv
rm d6.csv d7.csv
wc -l *.csv
#
time curl 'http://localhost:8983/solr/ucjeps-metadata/update/csv?commit=true&header=true&trim=true&separator=%7C&f.locality_ss.split=true&f.locality_ss.separator=%3B&f.blobs_ss.split=true&f.blobs_ss.separator=,' --data-binary @4solr.$HOST.metatadata.csv -H 'Content-type:text/plain; charset=utf-8'
date
