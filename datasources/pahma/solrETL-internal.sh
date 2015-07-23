#!/bin/bash -x
#
##############################################################################
# this script stitches together the data for the "internal" portal.
# it uses the results of the public datastore ETL, adding restrict data
# elements, etc.
# therefore, it has to run after both the public datastore ETL
# (it does not use the location ETL output  -- the public datastore ETL
# does the exraction for both internal and public datastores)
#
# features of the 'internal' metadata, so far:
#
# un-obfuscated latlongs
# all images, "in the clear",  including catalog cards
# museum location info
#
##############################################################################
date
cd /home/app_solr/solrdatasources/pahma
TENANT=$1
HOSTNAME="dba-postgres-prod-32.ist.berkeley.edu port=5307 sslmode=prefer"
export NUMCOLS=38
USERNAME="reporter_pahma"
DATABASE="pahma_domain_pahma"
CONNECTSTRING="host=$HOSTNAME dbname=$DATABASE"
##############################################################################
# run the "all media query"
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f mediaAllImages.sql   -o i4.csv
# cleanup newlines and crlf in data, then switch record separator.
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' i4.csv > 4solr.$TENANT.allmedia.csv
rm i4.csv
##############################################################################
# gunzip the internal metadata, prepared by the solrETL-internal.sh
##############################################################################
gunzip 4solr.$TENANT.baseinternal.csv.gz
##############################################################################
# add the blob csids to the rest of the internal
##############################################################################
time perl mergeObjectsAndMedia.pl 4solr.$TENANT.allmedia.csv 4solr.$TENANT.baseinternal.csv > d7.csv
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
grep csid d7.csv > header4Solr.csv
# add the blob field name to the header (the header already ends with a tab)
perl -i -pe 's/$/blob_ss/' header4Solr.csv
grep -v csid d7.csv > d8.csv
cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > 4solr.$TENANT.internal.csv
# clean up some outstanding sins perpetuated by other scripts
# perl -i -pe 's/\r//g;s/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;s/\"\"/"/g' 4solr.$TENANT.internal.csv
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
rm d7.csv d8.csv
wc -l *.csv
##############################################################################
# ok, now let's load this into solr...
# clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# this POSTs the csv to the Solr / update endpoint
# note, among other things, the overriding of the encapsulator with \
##############################################################################
time curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update/csv?commit=true&header=true&separator=%09&f.objaltnum_ss.split=true&f.objaltnum_ss.separator=%7C&f.objfilecode_ss.split=true&f.objfilecode_ss.separator=%7C&f.objdimensions_ss.split=true&f.objdimensions_ss.separator=%7C&f.objmaterials_ss.split=true&f.objmaterials_ss.separator=%7C&f.objinscrtext_ss.split=true&f.objinscrtext_ss.separator=%7C&f.objcollector_ss.split=true&f.objcollector_ss.separator=%7C&f.objaccno_ss.split=true&f.objaccno_ss.separator=%7C&f.objaccdate_ss.split=true&f.objaccdate_ss.separator=%7C&f.objacqdate_ss.split=true&f.objacqdate_ss.separator=%7C&f.objassoccult_ss.split=true&f.objassoccult_ss.separator=%7C&f.objculturetree_ss.split=true&f.objculturetree_ss.separator=%7C&f.exhibitionnumber_ss.split=true&f.exhibitionnumber_ss.separator=%7C&f.exhibitiontitle_ss.split=true&f.exhibitiontitle_ss.separator=%7C&f.grouptitle_ss.split=true&f.grouptitle_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" --data-binary @4solr.$TENANT.internal.csv -H 'Content-type:text/plain; charset=utf-8'
##############################################################################
# wrap things up: make a gzipped version of what was loaded
##############################################################################
rm 4solr.$TENANT.allmedia.csv.gz 4solr.$TENANT.internal.csv.gz
gzip 4solr.*.csv
date
