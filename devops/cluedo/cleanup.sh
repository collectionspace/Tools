cut -f4 personauthorities.created.csv | perl -pe 's/\r//' | ./helper.sh delete 49d792ea-585b-4d38-b591 personauthorities
cut -f4 locationauthorities.created.csv | perl -pe 's/\r//' | ./helper.sh delete 2105d470-0d15-47e5-88ed locationauthorities
cut -f4 collectionobjects.created.csv | perl -pe 's/\r//' | ./helper.sh delete "" collectionobjects
cut -f4 movements.created.csv | perl -pe 's/\r//' | ./helper.sh delete "" movements
