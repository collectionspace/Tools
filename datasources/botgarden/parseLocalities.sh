#
# hack of a utility script to analyze Locality field
#
cut -f27 -d"|" 4s.csv | sort | uniq -c | sort -rn | perl -pe 's/^ *(\d+) /\1\t/' > localities.csv
perl -ne 'chomp; $x = $_ ; s/^.*?\t//;s/, +/,/g;s/Geographic range: +//; @y=split ",",",,,,," . $_; print $x; print join "\t",@y[$#y - 5 .. $#y]; print "\n";' localities.csv > ex.csv
