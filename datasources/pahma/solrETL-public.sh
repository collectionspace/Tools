#!/bin/bash -x
#
##############################################################################
# shell script to extract multiple tabular data files from CSpace,
# "stitch" them together (see join.py)
# prep them for load into Solr4 using the "csv data import handler"
##############################################################################
date
cd /home/app_solr/solrdatasources/pahma
##############################################################################
# move the current set of extracts to temp (thereby saving the previous run, just in case)
# note that in this case there are 4 nightly scripts, public, internal, and locations,
# and osteology. internal depends on data created by public, so this case has to be handled
# specially, and the scripts need to run in order: public > internal > locations
# the public script, which runs first, *can* 'stash' last night's files...
##############################################################################
mv 4solr.*.csv.gz /tmp
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
# nb: using prod db for now... dev is too slow
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5307 sslmode=prefer"
USERNAME="reporter_$TENANT"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
FCPCOL=35
PUBLICCOLS=37
# the internal dataset has 7 more columns than the public one
INTERNALCOLS=44
##############################################################################
# run the "all media query"
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f mediaAllImages.sql   -o i4.csv
# cleanup newlines and crlf in data, then switch record separator.
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' i4.csv > 4solr.$TENANT.allmedia.csv
rm i4.csv
##############################################################################
# start the stitching process: extract the "basic" data (both restricted and unrestricted)
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f basic_restricted.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > basic_restricted.csv
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f basic_all.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > basic_all.csv
##############################################################################
# stitch this together with the results of the rest of the "subqueries"
##############################################################################
cp basic_restricted.csv restricted.csv
cp basic_all.csv all.csv
for i in {1..17}
do
 time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f part$i.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > part$i.csv
 time python join.py restricted.csv part$i.csv > temp.csv
 cp temp.csv restricted.csv
 time python join.py all.csv part$i.csv > temp.csv
 cp temp.csv all.csv
done
##############################################################################
# check latlongs for restricted (i.e. public) datastore
##############################################################################
perl -ne "@y=split /\t/;@x=split ',',$y[\$ENV{FCPCOL}];print if     ((abs($x[0])<90 && abs($x[1])<180 && $y[\$ENV{FCPCOL}]!~/[^0-9\, \.\-]/) || $y[\$ENV{FCPCOL}]=~/_p/);" restricted.csv > d6.csv
perl -ne "@y=split /\t/;@x=split ',',$y[\$ENV{FCPCOL}];print unless ((abs($x[0])<90 && abs($x[1])<180 && $y[\$ENV{FCPCOL}]!~/[^0-9\, \.\-]/) || $y[\$ENV{FCPCOL}]=~/_p/);" restricted.csv > errors_in_latlong.csv
mv d6.csv restricted.csv
##############################################################################
# check latlongs for internal datastore
##############################################################################
perl -ne "@y=split /\t/;@x=split ',',$y[\$ENV{FCPCOL}];print if     ((abs($x[0])<90 && abs($x[1])<180 && $y[\$ENV{FCPCOL}]!~/[^0-9\, \.\-]/) || $y[\$ENV{FCPCOL}]=~/_p/);" all.csv > d6.csv
# nb: we don't have to save the errors in this datastore, they will be the same as the restricted one.
# perl -ne "@y=split /\t/;@x=split ',',$y[\$ENV{FCPCOL}];print unless ((abs($x[0])<90 && abs($x[1])<180 && $y[\$ENV{FCPCOL}]!~/[^0-9\, \.\-]/) || $y[\$ENV{FCPCOL}]=~/_p/);" all.csv > errors_in_latlong.csv
##############################################################################
# these queries are for the internal datastore
##############################################################################
mv d6.csv internal.csv
for i in {18..21}
do
 time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f part$i.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > part$i.csv
 time python join.py internal.csv part$i.csv > temp.csv
 cp temp.csv internal.csv
done
rm temp.csv
##############################################################################
# check to see that each row has the right number of columns (solr4 will barf)
##############################################################################
time perl -ne " \$x = \$_ ;s/[^\t]//g; if     (length eq \$ENV{PUBLICCOLS}) { print \$x;}" restricted.csv | perl -pe 's/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;' > 4solr.$TENANT.public.csv &
time perl -ne " \$x = \$_ ;s/[^\t]//g; unless (length eq \$ENV{PUBLICCOLS}) { print \$x;}" restricted.csv | perl -pe 's/\\/\//g' > errors.public.csv &
wait
rm restricted.csv
##############################################################################
# check to see that each row has the right number of columns (solr4 will barf)
##############################################################################
time perl -ne " \$x = \$_ ;s/[^\t]//g; if     (length eq \$ENV{INTERNALCOLS}) { print \$x;}" internal.csv | perl -pe 's/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;' > 4solr.$TENANT.baseinternal.csv &
time perl -ne " \$x = \$_ ;s/[^\t]//g; unless (length eq \$ENV{INTERNALCOLS}) { print \$x;}" internal.csv | perl -pe 's/\\/\//g' > errors.internal.csv &
wait
rm internal.csv all.csv
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
grep csid 4solr.$TENANT.baseinternal.csv > header4Solr.csv
grep -v csid 4solr.$TENANT.baseinternal.csv > d8.csv
cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > 4solr.$TENANT.baseinternal.csv
##############################################################################
# add the blob and card csids and other flags to the rest of the metadata
##############################################################################
time perl mergeObjectsAndMediaPAHMA.pl 4solr.$TENANT.allmedia.csv 4solr.$TENANT.public.csv public > d6.csv
##############################################################################
#  compute a boolean: hascoords = yes/no
##############################################################################
perl setCoords.pl ${FCPCOL} < d6.csv > d6a.csv
##############################################################################
#  Obfuscate the lat-longs of sensitive sites
##############################################################################
time python obfuscateUSArchaeologySites.py d6a.csv d7.csv
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
grep csid d7.csv > header4Solr.csv
grep -v csid d7.csv > d8.csv
cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > 4solr.$TENANT.public.csv
# clean up some outstanding sins perpetuated by obfuscateUSArchaeologySites.py
perl -i -pe 's/\r//g;s/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;s/\"\"/"/g' 4solr.$TENANT.public.csv
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
wc -l *.csv
##############################################################################
# ok, now let's load this into solr...
# clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-public/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-public/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# this POSTs the csv to the Solr / update endpoint
# note, among other things, the overriding of the encapsulator with \
##############################################################################
time curl -S -s "http://localhost:8983/solr/${TENANT}-public/update/csv?commit=true&header=true&separator=%09&f.objaltnum_ss.split=true&f.objaltnum_ss.separator=%7C&f.objfilecode_ss.split=true&f.objfilecode_ss.separator=%7C&f.objdimensions_ss.split=true&f.objdimensions_ss.separator=%7C&f.objmaterials_ss.split=true&f.objmaterials_ss.separator=%7C&f.objinscrtext_ss.split=true&f.objinscrtext_ss.separator=%7C&f.objcollector_ss.split=true&f.objcollector_ss.separator=%7C&f.objaccno_ss.split=true&f.objaccno_ss.separator=%7C&f.objaccdate_ss.split=true&f.objaccdate_ss.separator=%7C&f.objacqdate_ss.split=true&f.objacqdate_ss.separator=%7C&f.objassoccult_ss.split=true&f.objassoccult_ss.separator=%7C&f.objculturetree_ss.split=true&f.objculturetree_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&f.card_ss.split=true&f.card_ss.separator=,&f.imagetype_ss.split=true&f.imagetype_ss.separator=,&encapsulator=\\" --data-binary @4solr.$TENANT.public.csv -H 'Content-type:text/plain; charset=utf-8'
##############################################################################
# wrap things up: make a gzipped version of what was loaded
##############################################################################
# get rid of intermediate files
rm d?.csv d6a.csv m?.csv part*.csv basic.csv
# zip up .csvs, save a bit of space on backups
gzip -f *.csv
date
