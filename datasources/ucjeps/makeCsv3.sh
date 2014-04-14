#!/bin/bash -x
date
cd /home/developers/ucjeps
HOST=$1
# extract metadata and media info from CSpace
time psql -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=csR2p4rt2r" -f ucjepsMetadataV2.sql -o d1.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1.csv > d3.csv 
time perl -ne '$x = $_ ;s/[^\|]//g; if (length eq 39) { print $x;} '     d3.csv | perl -pe 's/\"/\\"/g;' > d4.csv
time perl -ne '$x = $_ ;s/[^\|]//g; unless (length eq 39) { print $x;} ' d3.csv | perl -pe 's/\"/\\"/g;' > errors.csv &
mv d4.csv metadata.csv
time psql -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=csR2p4rt2r" -f ucjepsMediaV1.sql -o m1.csv 
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m1.csv > media.csv 
rm m1.csv d1.csv d3.csv
# add the blobcsids to the rest of the data
time perl mergeObjectsAndMedia.pl > d6.csv
# we want to use our "special" solr-friendly header.
tail -n +2 d6.csv | perl fixdate.pl > d7.csv
cat metadataHeaderV3.csv d7.csv > 4solr.$HOST.metadata.csv
rm d6.csv d7.csv
wc -l *.csv
# clear out the existing data
curl "http://localhost:8983/solr/ucjeps-metadata/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'  
curl "http://localhost:8983/solr/ucjeps-metadata/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl 'http://localhost:8983/solr/ucjeps-metadata/update/csv?commit=true&header=true&trim=true&separator=%7C&f.previousdeterminations_ss.split=true&f.previousdeterminations_ss.separator=;&f.associatedtaxa_ss.split=true&f.associatedtaxa_ss.separator=;&f.typeassertions_ss.split=true&f.typeassertions_ss.separator=;&f.othernumbers_ss.split=true&f.othernumbers_ss.separator=;&f.blobs_ss.split=true&f.blobs_ss.separator=,' --data-binary @4solr.$HOST.metadata.csv -H 'Content-type:text/plain; charset=utf-8'
date
