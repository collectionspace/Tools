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
CONTACT="mtblack@berkeley.edu"
FCPCOL=35
export PUBLICCOLS=38
# the internal dataset has 7 more columns than the public one
export INTERNALCOLS=45
##############################################################################
# run the "all media query"
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f mediaAllImages.sql -o i4.csv
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
cp basic_all.csv internal.csv
for i in {1..20}
do
 if [ -e part$i.sql ]; then
     time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f part$i.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > part$i.csv
     time python join.py restricted.csv part$i.csv > temp1.csv &
     time python join.py internal.csv part$i.csv > temp2.csv &
     wait
     mv temp1.csv restricted.csv
     mv temp2.csv internal.csv
 fi
done
##############################################################################
# these queries are for the internal datastore
##############################################################################
for i in {21..25}
do
 if [ -e part$i.sql ]; then
    time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f part$i.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' | sort > part$i.csv
    time python join.py internal.csv part$i.csv > temp.csv
    mv temp.csv internal.csv
 fi
done
##############################################################################
# internal.csv and restricted.csv contain the basic metadata for the internal
# and public portals respectively. The script keeps these around for
# debugging.
# no other accesses to the database are made after this point
#
# the script from here on uses only three files: these two and
# 4solr.$TENANT.allmedia.csv, so if you wanted to re-run the next chunks of
# the ETL, you can use these files for that purpose.
##############################################################################
# check to see that each row has the right number of columns (solr4 will barf)
##############################################################################
time perl -ne '$x = $_ ;s/[^\t]//g; if     (length == $ENV{PUBLICCOLS}) { print $x;}' restricted.csv | perl -pe 's/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;' > temp.public.csv &
time perl -ne '$x = $_ ;s/[^\t]//g; unless (length == $ENV{PUBLICCOLS}) { print $x;}' restricted.csv | perl -pe 's/\\/\//g' > errors.public.csv &
time perl -ne '$x = $_ ;s/[^\t]//g; if     (length == $ENV{INTERNALCOLS}) { print $x;}' internal.csv | perl -pe 's/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;' > temp.internal.csv &
time perl -ne '$x = $_ ;s/[^\t]//g; unless (length == $ENV{INTERNALCOLS}) { print $x;}' internal.csv | perl -pe 's/\\/\//g' > errors.internal.csv &
wait
##############################################################################
# check latlongs for public datastore
##############################################################################
perl -ne '@y=split /\t/;@x=split ",",$y[35];print if     ((abs($x[0])<90 && abs($x[1])<180 && $y[35]!~/[^0-9\, \.\-]/) || $y[35]=~/_p/);' temp.public.csv > d6a.csv &
perl -ne '@y=split /\t/;@x=split ",",$y[35];print unless ((abs($x[0])<90 && abs($x[1])<180 && $y[35]!~/[^0-9\, \.\-]/) || $y[35]=~/_p/);' temp.public.csv > errors_in_latlong.csv &
##############################################################################
# check latlongs for internal datastore
##############################################################################
perl -ne '@y=split /\t/;@x=split ",",$y[35];print if     ((abs($x[0])<90 && abs($x[1])<180 && $y[35]!~/[^0-9\, \.\-]/) || $y[35]=~/_p/);' temp.internal.csv > d6b.csv &
# nb: we don't have to save the errors in this datastore, they will be the same as the restricted one.
# perl -ne "@y=split /\t/;@x=split ',',$y[\$ENV{FCPCOL}];print unless ((abs($x[0])<90 && abs($x[1])<180 && $y[\$ENV{FCPCOL}]!~/[^0-9\, \.\-]/) || $y[\$ENV{FCPCOL}]=~/_p/);" temp.internal.csv > errors_in_latlong.csv
wait
mv d6a.csv temp.public.csv
mv d6b.csv temp.internal.csv
##############################################################################
# add the blob and card csids and other flags to the rest of the metadata
##############################################################################
time perl mergeObjectsAndMediaPAHMA.pl 4solr.$TENANT.allmedia.csv temp.public.csv public > d6a.csv &
time perl mergeObjectsAndMediaPAHMA.pl 4solr.$TENANT.allmedia.csv temp.internal.csv internal > d6b.csv &
wait
mv d6a.csv temp.public.csv
mv d6b.csv temp.internal.csv
##############################################################################
#  compute a boolean: hascoords = yes/no
##############################################################################
time perl setCoords.pl ${FCPCOL} < temp.public.csv   > d6a.csv &
time perl setCoords.pl ${FCPCOL} < temp.internal.csv > d6b.csv &
wait
##############################################################################
#  Obfuscate the lat-longs of sensitive sites for public portal
##############################################################################
time python obfuscateUSArchaeologySites.py d6a.csv d7.csv
##############################################################################
# clean up some outstanding sins perpetuated by obfuscateUSArchaeologySites.py
##############################################################################
time perl -i -pe 's/\r//g;s/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;s/\"\"/"/g' d7.csv
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
time grep -P "^id\t" d7.csv > header4Solr.csv &
time grep -v -P "^id\t" d7.csv > d8.csv &
wait
cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > 4solr.$TENANT.public.csv
#
time grep -P "^id\t" d6b.csv > header4Solr.csv &
time grep -v -P "^id\t" d6b.csv > d8.csv &
wait
cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > 4solr.$TENANT.internal.csv
#
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
time curl -S -s "http://localhost:8983/solr/${TENANT}-public/update/csv?commit=true&header=true&separator=%09&objpp_ss.split=true&fobjpp_ss.separator=%7C&anonymousdonor_ss.split=true&f.anonymousdonor_ss.separator=%7C&f.objaltnum_ss.split=true&f.objaltnum_ss.separator=%7C&f.objfilecode_ss.split=true&f.objfilecode_ss.separator=%7C&f.objdimensions_ss.split=true&f.objdimensions_ss.separator=%7C&f.objmaterials_ss.split=true&f.objmaterials_ss.separator=%7C&f.objinscrtext_ss.split=true&f.objinscrtext_ss.separator=%7C&f.objcollector_ss.split=true&f.objcollector_ss.separator=%7C&f.objaccno_ss.split=true&f.objaccno_ss.separator=%7C&f.objaccdate_ss.split=true&f.objaccdate_ss.separator=%7C&f.objacqdate_ss.split=true&f.objacqdate_ss.separator=%7C&f.objassoccult_ss.split=true&f.objassoccult_ss.separator=%7C&f.objculturetree_ss.split=true&f.objculturetree_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&f.card_ss.split=true&f.card_ss.separator=,&f.imagetype_ss.split=true&f.imagetype_ss.separator=,&encapsulator=\\" --data-binary @4solr.$TENANT.public.csv -H 'Content-type:text/plain; charset=utf-8'
##############################################################################
# wrap things up: make a gzipped version of what was loaded
##############################################################################
# send the errors off to be dealt with
tar -czf errors.tgz errors*.csv
./make_error_report.sh | mail -a errors.tgz -s "PAHMA Solr Refresh Errors `date`" ${CONTACT}
# ./make_error_report.sh | mail -a errors.tgz -s "PAHMA Solr Refresh Errors `date`" cspace-app-logs@lists.berkeley.edu
# get rid of intermediate files
rm d?.csv d6?.csv m?.csv part*.csv temp.*.csv basic*.csv errors*.csv header4Solr.csv
# zip up .csvs, save a bit of space on backups
gzip -f *.csv
date
