#!/bin/bash -x
date
#cd /home/developers/botgarden
HOST=$1
PASSWORD=$2
NUMFIELDS=27
##############################################################################
# extract propagations info from CSpace
##############################################################################
time psql  -F $'\t' -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=$PASSWORD" -f botgardenPropagations.sql -o p1.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' p1.csv > p2.csv 
time perl -ne 'print unless /\(\d+ rows\)/' p2.csv > p3.csv
time perl -ne '$x = $_ ;s/[^\t]//g; if (length eq $ENV{NUMFIELDS}) { print $x;} '     p3.csv | perl -pe 's/\"/\\"/g;' > p4.csv
time perl -ne '$x = $_ ;s/[^\t]//g; unless (length eq $ENV{NUMFIELDS}) { print $x;} ' p3.csv | perl -pe 's/\"/\\"/g;' > errors.csv &
head -1 p4.csv | perl -pe 's/\t/_s\t/g;s/_s//;s/$/_s/;' > header4Solr.csv
#tail -n +2 p4.csv | perl fixdate.pl > d7.csv
tail -n +2 p4.csv > p5.csv
cat header4Solr.csv p5.csv > 4solr.$HOST.propagations.csv
##############################################################################
# here are the schema changes needed: copy all the _s and _ss to _txt, and vv.
##############################################################################
rm schemaFragment.xml
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_s/; s/_s$//; print "    <copyField source=\"" .$_."_s\" dest=\"".$_."_txt\"/>\n"' >> schemaFragment.xml
##############################################################################
# here are the solr csv update parameters needed for multivalued fields
##############################################################################
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_ss/; next if /blob/; print "f.$_.split=true&f.$_.separator=%7C&"' > uploadparms.txt

rm d7.csv
wc -l *.csv
#
curl "http://localhost:8983/solr/${HOST}-propagations/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'  
curl "http://localhost:8983/solr/${HOST}-propagations/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl "http://localhost:8983/solr/${HOST}-propagations/update/csv?commit=true&header=true&trim=true&separator=%09" --data-binary @4solr.$HOST.propagations.csv -H 'Content-type:text/plain; charset=utf-8'
date
