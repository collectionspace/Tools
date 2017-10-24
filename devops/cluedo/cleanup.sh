#
# remove records created by last run
#
personauthorities=`./getauthoritycsid.sh personauthorities`
locationauthorities=`./getauthoritycsid.sh locationauthorities`

cut -f4 collectionobjects.created.csv | perl -pe 's/\r//' | ./helper.sh delete "" collectionobjects
time python delete_movements.py movements.created.csv
cut -f4 media.created.csv | perl -pe 's/\r//' | ./helper.sh delete "" media

cut -f4 personauthorities.created.csv | perl -pe 's/\r//' | ./helper.sh delete $personauthorities personauthorities
cut -f4 locationauthorities.created.csv | perl -pe 's/\r//' | ./helper.sh delete $locationauthorities locationauthorities

