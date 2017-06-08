
personauthorities=`./getauthoritycsid.sh personauthorities`
locationauthorities=`./getauthoritycsid.sh locationauthorities`

cut -f4 personauthorities.created.csv | perl -pe 's/\r//' | ./helper.sh delete $personauthorities personauthorities
cut -f4 locationauthorities.created.csv | perl -pe 's/\r//' | ./helper.sh delete $locationauthorities locationauthorities
cut -f4 collectionobjects.created.csv | perl -pe 's/\r//' | ./helper.sh delete "" collectionobjects
cut -f4 movements.created.csv | perl -pe 's/\r//' | ./helper.sh delete "" movements
