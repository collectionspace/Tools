#!/bin/bash -x
date
cd /home/developers/botgarden
HOST=$1
# extract metadata and media info from CSpace
time psql -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=csR2p4rt2r" -f botgardenMetadataV1alive.sql -o d1a.csv
time psql -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=csR2p4rt2r" -f botgardenMetadataV1dead.sql -o d1b.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1a.csv > d3.csv 
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1b.csv >> d3.csv 
time perl -ne '$x = $_ ;s/[^\|]//g; if (length eq 32) { print $x;} '     d3.csv | perl -pe 's/\"/\\"/g;' > d4.csv
time perl -ne '$x = $_ ;s/[^\|]//g; unless (length eq 32) { print $x;} ' d3.csv | perl -pe 's/\"/\\"/g;' > errors.csv &
mv d4.csv metadata.csv
rm d1?.csv d3.csv
# we want to use our "special" solr-friendly header.
tail -n +2 metadata.csv | perl fixdate.pl > d7.csv
cat metadataHeaderV2.csv d7.csv > 4solr.$HOST.metadata.csv
rm d7.csv
wc -l *.csv
#
curl "http://localhost:8983/solr/${HOST}-metadata/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'  
curl "http://localhost:8983/solr/${HOST}-metadata/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl "http://localhost:8983/solr/${HOST}-metadata/update/csv?commit=true&header=true&trim=true&separator=%7C&f.blobs_ss.split=true&f.blobs_ss.separator=," --data-binary @4solr.$HOST.metadata.csv -H 'Content-type:text/plain; charset=utf-8'
date
