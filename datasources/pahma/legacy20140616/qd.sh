#!/bin/bash -x
#
# you run this as: ./qd.sh > qd.report >& qd.report &
#
# jbl 4/5/13
#
set -v
#perl -ne "print if /\|1\-1439\|/" delphi.csv 
cut -f3 -d"|" delphi.csv > objectnames.txt
wc -l objectnames.txt
# make a concordance of object names, pareto-ordered
sort objectnames.txt | uniq -c | sort -rn | perl -pe "s/^ +(\d+) /\1\t/" > objectnames.concordance.csv
wc -l objectnames.concordance.csv
head -20 objectnames.concordance.csv 
# how many occur once...
perl -ne 'print if /^1\t/' objectnames.concordance.csv | wc
# how many occur twice...
perl -ne 'print if /^2\t/' objectnames.concordance.csv | wc
# examine "projectile point" a little..
grep -i 'projectile' objectnames.concordance.csv | wc -l
grep -i 'projectile' objectnames.concordance.csv | grep -v -i 'point' | wc -l
grep -i 'projectile' objectnames.concordance.csv | grep -v -i 'point' | head -20
# count number of "normalized" values
perl -pe 'tr/A-Z/a-z/;s/\d+[,\.]*\d*/99/g;s/\W+/ /g;print "\n"' objectnames.txt | sort | uniq -c | perl -pe 's/^ +(\d+) /\1\t/' > normalizednames.csv
wc -l normalizednames.csv
# count number of "normalized" values, collapsed (most) plurals (i.e. remove -s)
perl -pe 'tr/A-Z/a-z/;s/s$//;s/\d+[,\.]*\d*/99/g;s/\W+/ /g;print "\n"' objectnames.txt | sort | uniq -c | perl -pe 's/^ +(\d+) /\1\t/' | wc -l
# make concordance of (lower-case) tokens
perl -pe "tr/A-Z/a-z/;s/\W+/\n/g" objectnames.txt | sort | uniq -c > objectnames.tokens.csv
wc -l objectnames.tokens.csv
perl -pe "tr/A-Z/a-z/;s/\W+/\n/g" objectnames.txt | wc -l
sort -rn objectnames.tokens.csv | head -40
head -20 objectnames.tokens.csv
tail -20 objectnames.tokens.csv
