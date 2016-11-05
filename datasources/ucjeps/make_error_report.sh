echo "Solr Refesh Errors `date`"
echo
wc -l errors*.csv
echo
echo "Unspecified data problems, probably stray newlines or tabs"
echo
cut -f2 errors.csv 
echo
echo "Errors in Coordinates"
echo
cut -f3 errors_in_latlong.csv
echo
