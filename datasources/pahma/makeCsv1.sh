#!/bin/bash -x
cd /home/developers/delphi
# extract metadata and media info from CSpace
time psql -R"@@" -A -U reporter -d "host=pahma.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f delphiV3.sql -o d1.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1.csv > d3.csv 
time perl -ne '$x = $_ ;s/[^\|]//g; if (length eq 23) { print $x;} '     d3.csv | perl -pe 's/\"/\\"/g;' > d4.csv
time perl -ne '$x = $_ ;s/[^\|]//g; unless (length eq 23) { print $x;} ' d3.csv | perl -pe 's/\"/\\"/g;' > errors.csv &
time psql -A -U reporter -d "host=pahma.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f delphiMediaV1.sql -o media.csv 
mv d4.csv metadata.csv
rm d1.csv d3.csv
# add the blobcsids to the rest of the data
time perl mergeObjectsAndMedia.pl > d6.csv
# we want to use our "special" solr-friendly header.
tail -n +2 d6.csv > d7.csv
cat header.csv d7.csv > delphi.csv
rm d6.csv
# rm d7.csv
wc -l *.csv
#
time curl 'http://localhost:8983/solr/metadata/update/csv?commit=true&header=true&separator=%7C&f.provenance_txt.split=true&f.provenance_txt.separator=,&f.blobs_ss.split=true&f.blobs_ss.separator=,' --data-binary @delphi.csv -H 'Content-type:text/plain; charset=utf-8'
