#!/bin/bash -x
date
cd /home/app_solr/solrdatasources/ucjeps
##############################################################################
# move the current set of extracts to temp (thereby saving the previous run, just in case)
# note that in the case where there are several nightly scripts, e.g. public and internal,
# like here, the one to run first will "clear out" the previous night's data.
# since we don't know which order these might run in, I'm leaving the mv commands in both
# nb: the jobs in general can't overlap as the have some files in common and would step
# on each other
##############################################################################
mv 4solr.*.csv.gz /tmp
##############################################################################
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintainance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
SERVER="dba-postgres-prod-42.ist.berkeley.edu port=5310 sslmode=prefer"
USERNAME="reporter_$TENANT"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
export NUMCOLS=57
##############################################################################
# extract and massage the metadata from CSpace
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f ucjepsMetadata.sql -o d1.csv
time perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' d1.csv > d3.csv
time perl -ne " \$x = \$_ ;s/[^\t]//g; if     (length eq \$ENV{NUMCOLS}) { print \$x;}" d3.csv > metadata.csv
time perl -ne " \$x = \$_ ;s/[^\t]//g; unless (length eq \$ENV{NUMCOLS}) { print \$x;}" d3.csv > errors.csv &
##############################################################################
# get media
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f ucjepsMedia.sql -o media.csv
time perl -i -pe 's/[\r\n]/ /g;s/\@\@/\n/g' media.csv 
##############################################################################
# make a unique sequence number for id
##############################################################################
perl -i -pe '$i++;print $i . "\t"' metadata.csv
##############################################################################
# add the blobcsids to mix (expects to read media.csv and metadata.csv)
##############################################################################
time perl mergeObjectsAndMedia.pl > d6.csv
##############################################################################
# we want to use our "special" solr-friendly header.
##############################################################################
tail -n +2 d6.csv | perl fixdate.pl > d7.csv
##############################################################################
# check latlongs
##############################################################################
perl -ne '@x=split /\t/;print if abs($x[22])<90 && abs($x[23])<180;' d7.csv > d8.csv
perl -ne '@x=split /\t/;print if !(abs($x[22])<90 && abs($x[23])<180);' d7.csv > errors_in_latlong.csv
##############################################################################
# snag UCBG accession number and stuff it in the right field
##############################################################################
perl -i -ne '@x=split /\t/;$x[49]="";($x[48]=~/U.?C.? Botanical Ga?r?de?n.*(\d\d+\.\d+)|(\d+\.\d+).*U.?C.? Botanical Ga?r?de?n/)&&($x[49]="$1$2");print join "\t",@x;' d8.csv
##############################################################################
# parse collector names
##############################################################################
perl -i -ne '@x=split /\t/;$_=$x[8];unless (/Paccard/ || (!/ [^ ]+ [^ ]+ [^ ]+/ && ! /,.*,/ && ! / (and|with|\&) /)) {s/,? (and|with|\&) /|/g;s/, /|/g;s/,? ?\[(in company|with) ?(.*?)\]/|\2/;s/\|Jr/, Jr/g;s/\|?et al\.?//;s/\|\|/|/g;};s/ \& /|/ if /Paccard/;$x[8]=$_;print join "\t",@x;' d8.csv
##############################################################################
# recover & use our "special" solr-friendly header, which got buried
##############################################################################
head -1 metadata.csv > header4Solr.csv
##############################################################################
# name the first column 'id'; add the blob field name to the header.
##############################################################################
perl -i -pe 's/^1\t/id\t/;s/$/\tblob_ss/;' header4Solr.csv
grep -v csid_s d8.csv > d9.csv
cat header4Solr.csv d9.csv | perl -pe 's/␥/|/g' > 4solr.$TENANT.public.csv
# clean up some stray quotes. Really this should get fixed properly someday!
perl -i -pe 's/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;s/\"\"/"/g' 4solr.$TENANT.public.csv
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
##############################################################################
#rm d?.csv m?.csv
##############################################################################
wc -l *.csv
##############################################################################
# clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-public/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# load the csv file into Solr using the csv DIH
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-public/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl -S -s "http://localhost:8983/solr/${TENANT}-public/update/csv?commit=true&header=true&trim=true&separator=%09&f.collector_ss.split=true&f.collector_ss.separator=%7C&f.previousdeterminations_ss.split=true&f.previousdeterminations_ss.separator=%7C&f.otherlocalities_ss.split=true&f.otherlocalities_ss.separator=%7C&f.associatedtaxa_ss.split=true&f.associatedtaxa_ss.separator=%7C&f.typeassertions_ss.split=true&f.typeassertions_ss.separator=%7C&f.alllocalities_ss.split=true&f.alllocalities_ss.separator=%7C&f.othernumber_ss.split=true&f.othernumber_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&f.card_ss.split=true&f.card_ss.separator=,&encapsulator=\\" --data-binary @4solr.$TENANT.public.csv -H 'Content-type:text/plain; charset=utf-8'
# get rid of intermediate files
rm d?.csv m?.csv metadata.csv media.csv
# zip up .csvs, save a bit of space on backups
gzip -f *.csv
date
