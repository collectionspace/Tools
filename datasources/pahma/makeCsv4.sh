#!/bin/bash -x
#
##############################################################################
# shell script to extract multiple tabular data files from CSpace,
# "stitch" them together (see join.py)
# prep them for load into Solr4 using the "csv datahandler"
##############################################################################
date
cd /home/developers/pahma
HOST=$1
##############################################################################
# extract media info from CSpace
##############################################################################
time psql -F $'\t' -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f mediaApprovedForWeb.sql -o m1.csv
time psql -F $'\t' -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f mediaRestricted.sql -o m2.csv
time psql -F $'\t' -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f mediaCatalogCards.sql -o m3.csv

# cleanup newlines and crlf in data, then switch record separator.
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m1.csv > 4solr.$HOST.mediaApprovedForWeb.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m2.csv > 4solr.$HOST.mediaRestricted.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' m3.csv > 4solr.$HOST.mediaCatalogCards.csv
rm m1.csv m2.csv m3.csv
cat 4solr.$HOST.mediaApprovedForWeb.csv 4solr.$HOST.mediaRestricted.csv > 4solr.$HOST.media.csv
##############################################################################
# start the stitching process: extract the "basic" data
##############################################################################
time psql -F $'\t' -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f basic.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > basic.csv
cp basic.csv intermediate.csv
##############################################################################
# stitch this together with the results of the rest of the "subqueries"
##############################################################################
for i in {1..17}
do
 time psql -F $'\t' -R"@@" -A -U reporter -d "host=$HOST.cspace.berkeley.edu dbname=nuxeo password=xxxpasswordxxx" -f part$i.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > part$i.csv
 time python join.py intermediate.csv part$i.csv > temp.csv
 cp temp.csv intermediate.csv
done
rm temp.csv
##############################################################################
# check to see that each row has the right number of columns (solr4 will barf)
##############################################################################
time perl -ne '$x = $_ ;s/[^\t]//g; if (length eq 36) { print $x;} ' intermediate.csv | perl -pe 's/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;' > 4solr.$HOST.metadata.csv
time perl -ne '$x = $_ ;s/[^\t]//g; unless (length eq 36) { print $x;} ' intermediate.csv | perl -pe 's/\\/\//g' > errors.csv
rm intermediate.csv
##############################################################################
# add the blob csids to the rest of the metadata
##############################################################################
time perl mergeObjectsAndMedia.pl 4solr.$HOST.media.csv 4solr.$HOST.metadata.csv > d6.csv
##############################################################################
#  Obfuscate the lat-longs of sensitive sites
##############################################################################
time python obfuscateUSArchaeologySites.py d6.csv d7.csv
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
grep csid d7.csv > header4Solr.csv
# add the blob field name to the header (the header already ends with a tab)
perl -i -pe 's/$/blob_ss/' header4Solr.csv
grep -v csid d7.csv > d8.csv
cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > 4solr.$HOST.metadata.csv
##############################################################################
# here are the schema changes needed: copy all the _s and _ss to _txt, and vv.
##############################################################################
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_txt/; s/_txt$//; print "    <copyField source=\"" .$_."_txt\" dest=\"".$_."_s\"/>\n"' > schemaFragment.xml
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_s$/; s/_s$//; print "    <copyField source=\"" .$_."_s\" dest=\"".$_."_txt\"/>\n"' >> schemaFragment.xml
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_ss$/; s/_ss$//; print "    <copyField source=\"" .$_."_ss\" dest=\"".$_."_txt\"/>\n"' >> schemaFragment.xml
##############################################################################
# here are the solr csv update parameters needed for multivalued fields
##############################################################################
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_ss/; next if /blob/; print "f.$_.split=true&f.$_.separator=%7C&"' > uploadparms.txt
rm d6.csv d7.csv d8.csv
wc -l *.csv
##############################################################################
# ok, now let's load this into solr...
# clear out the existing data
##############################################################################
curl "http://localhost:8983/solr/${HOST}-metadata/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl "http://localhost:8983/solr/${HOST}-metadata/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# this POSTs the csv to the Solr / update endpoint
# note, among other things, the overriding of the encapsulator with \
##############################################################################
time curl "http://localhost:8983/solr/${HOST}-metadata/update/csv?commit=true&header=true&separator=%09&f.objaltnum_ss.split=true&f.objaltnum_ss.separator=%7C&f.objfilecode_ss.split=true&f.objfilecode_ss.separator=%7C&f.objdimensions_ss.split=true&f.objdimensions_ss.separator=%7C&f.objmaterials_ss.split=true&f.objmaterials_ss.separator=%7C&f.objinscrtext_ss.split=true&f.objinscrtext_ss.separator=%7C&f.objcollector_ss.split=true&f.objcollector_ss.separator=%7C&f.objaccno_ss.split=true&f.objaccno_ss.separator=%7C&f.objaccdate_ss.split=true&f.objaccdate_ss.separator=%7C&f.objacqdate_ss.split=true&f.objacqdate_ss.separator=%7C&f.objassoccult_ss.split=true&f.objassoccult_ss.separator=%7C&f.objculturetree_ss.split=true&f.objculturetree_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" --data-binary @4solr.$HOST.metadata.csv -H 'Content-type:text/plain; charset=utf-8'
##############################################################################
# wrap things up: make a gzipped version of what was loaded
##############################################################################
rm 4solr*.csv.gz
gzip 4solr.*.csv
date
