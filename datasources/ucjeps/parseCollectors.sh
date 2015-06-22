#!/usr/bin/env bash
# this file shows how the 'collector name parser' works and how it operates.
# it can be used to refine the parser...it extracts the name, runs the parser, outputs a few lines of the result...
# it is NOT the parser, which is a one liner in the middle of the solrETL-public.sh ETL script
#
# ssh to the CSpace Dev server, where there is a current csv file with all the collectors
# go to the data directory, get the data
cd /home/app_solr/solrdatasources/ucjeps/
gunzip -c 4solr.ucjeps.metadata.csv.gz 4solr.ucjeps.metadata.csv
# make a list of collector names
cut -f9 4solr.ucjeps.metadata.csv | sort -u > collectors
# here's a regex that seems to divide up all the names with vertical bars (these are parsed as separate values by the solr4 loader)
perl -pe 'chomp;print "\n";print $_; unless (/Paccard/ || (!/ [^ ]+ [^ ]+ [^ ]+/ && ! /,.*,/ && ! / (and|with|\&) /)) {s/,? (and|with|\&) /|/g;s/, /|/g;s/,? ?\[(in company|with) ?(.*?)\]/|\2/;s/\|Jr/, Jr/g;s/\|?et al\.?//;s/\|\|/|/g;};s/ \& /|/ if /Paccard/;' collectors > names
# the 'names' file now has each name, with the "parsed version", separated by a tab
grep "|" names | grep Jepson | head -30 | tail -20 | expand -40
expand -50 names | sed -n '1p;0~300p' | grep "|" | head -20
# extract the name patterns, list in Zipfian order, list first 20
perl -pe 's/ and / 99 /g;s/ with / 88 /g;s/[A-Z]+/X/g;s/[a-z]+/xx/g;s/[Xx\. ]+?/X/g;s/X+/X/g;s/ *99 */ and /g;s/ *88 */ with /g;s/,/, /g;s/ +/ /g' names | sort | uniq -c  | grep "|" | sort -rn | head -20 | expand -40
rm 4solr.ucjeps.metadata.csv