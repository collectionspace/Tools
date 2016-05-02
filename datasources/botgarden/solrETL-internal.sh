#!/bin/bash -x
date
cd /home/app_solr/solrdatasources/botgarden
##############################################################################
# move the current set of extracts to temp (thereby saving the previous run, just in case)
# note that in the case where there are several nightly scripts, e.g. public and internal,
# like here, the one to run first will "clear out" the previous night's data.
# since we don't know which order these might run in, I'm leaving the mv commands in both
# nb: the jobs in general can't overlap as the have some files in common and would step
# on each other
##############################################################################
# mv 4solr.*.csv.gz /tmp
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5313 sslmode=prefer"
USERNAME="reporter_$TENANT"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
export NUMCOLS=46
##############################################################################
# extract metadata (dead and alive) info from CSpace
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f botgardenMetadataV1alive.sql -o d1a.csv
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f botgardenMetadataV1dead.sql -o d1b.csv
# some fix up required, alas: data from cspace is dirty: contain csv delimiters, newlines, etc. that's why we used @@ as temporary record separator
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1b.csv > d2b.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1a.csv > d2a.csv
cat d2b.csv d2a.csv > d2.csv
time perl -ne 'print unless /\(\d+ rows\)/' d2.csv > d3.csv
time perl -ne " \$x = \$_ ;s/[^\t]//g; if     (length eq \$ENV{NUMCOLS}) { print \$x;}" d3.csv > d4.csv
time perl -ne " \$x = \$_ ;s/[^\t]//g; unless (length eq \$ENV{NUMCOLS}) { print \$x;}" d3.csv > errors.csv &
##############################################################################
# run the media query
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f media.sql  -o i4.csv
# cleanup newlines and crlf in data, then switch record separator.
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' i4.csv > 4solr.$TENANT.media.csv
rm i4.csv
##############################################################################
# check latlongs
##############################################################################
perl -ne '@y=split /\t/;@x=split ",",$y[17];print if  (abs($x[0])<90 && abs($x[1])<180);' d4.csv > d5.csv
perl -ne '@y=split /\t/;@x=split ",",$y[17];print if !(abs($x[0])<90 && abs($x[1])<180);' d4.csv > errors_in_latlong.csv
##############################################################################
# temporary hack to parse Locality into County/State/Country
##############################################################################
perl fixLocalites.pl d5.csv > metadata.csv
cut -f10 metadata.csv | perl -pe 's/\|/\n/g;' | sort | uniq -c | perl -pe 's/^ *(\d+) /\1\t/' > county.csv
cut -f11 metadata.csv | perl -pe 's/\|/\n/g;' | sort | uniq -c | perl -pe 's/^ *(\d+) /\1\t/' > state.csv
cut -f12 metadata.csv | perl -pe 's/\|/\n/g;' | sort | uniq -c | perl -pe 's/^ *(\d+) /\1\t/' > country.csv
rm d3.csv
##############################################################################
# make a unique sequence number for id
##############################################################################
perl -i -pe '$i++;print $i . "\t"' metadata.csv
python gbif/parseAndInsertGBIFparts.py metadata.csv metadata+parsednames.csv gbif/names.pickle 3
##############################################################################
# we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
grep csid metadata+parsednames.csv | head -1 > header4Solr.csv
perl -i -pe 's/^1\tid/id\tobjcsid_s/' header4Solr.csv
perl -i -pe 's/$/\tblob_ss/' header4Solr.csv
grep -v csid metadata+parsednames.csv > d7.csv
python fixfruits.py d7.csv > d8.csv
##############################################################################
# add the blob csids to the rest of the internal
##############################################################################
time perl mergeObjectsAndMedia.pl 4solr.$TENANT.media.csv d8.csv > d9.csv
cat header4Solr.csv d9.csv | perl -pe 's/␥/|/g' > 4solr.$TENANT.internal.csv
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
perl -i -pe 's/International Union for Conservation of Nature and Natural Resources/IUCN/g' 4solr.$TENANT.internal.csv
wc -l *.csv
#
curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update/csv?commit=true&header=true&trim=true&separator=%09&f.fruiting_ss.split=true&f.fruiting_ss.separator=%7C&f.flowering_ss.split=true&f.flowering_ss.separator=%7C&f.fruitingverbatim_ss.split=true&f.fruitingverbatim_ss.separator=%7C&f.floweringverbatim_ss.split=true&f.floweringverbatim_ss.separator=%7C&f.collcounty_ss.split=true&f.collcounty_ss.separator=%7C&f.collstate_ss.split=true&f.collstate_ss.separator=%7C&f.collcountry_ss.split=true&f.collcountry_ss.separator=%7C&f.conservationinfo_ss.split=true&f.conservationinfo_ss.separator=%7C&f.conserveorg_ss.split=true&f.conserveorg_ss.separator=%7C&f.conservecat_ss.split=true&f.conservecat_ss.separator=%7C&f.voucherlist_ss.split=true&f.voucherlist_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" --data-binary @4solr.$TENANT.internal.csv -H 'Content-type:text/plain; charset=utf-8'
# get rid of intermediate files
rm d?.csv d??.csv m?.csv metadata*.csv
# zip up .csvs, save a bit of space on backups
gzip -f 4solr.*.csv
date
