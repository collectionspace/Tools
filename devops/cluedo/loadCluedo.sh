#!/bin/bash -x 
####
echo Loading Cluedo Museum...
date

# 1. extract goodies to load from the XML source file, cluedo.xml
# the hardcoded output .CSV file is 'entities.csv'
python makeCSV.py cluedo.xml

# 2. we need to create our authority records first
#
# these are values for nightly.collectionspace.org
personauthorities=`./getauthoritycsid.sh personauthorities`
locationauthorities=`./getauthoritycsid.sh locationauthorities`

time python loadCSpace.py entities.csv person personauthorities $personauthorities
time python loadCSpace.py entities.csv storagelocation locationauthorities $locationauthorities
#time python loadCSpace.py entities.csv material conceptauthorites

# 3. now we can make some object records, and some movement records that
# will later specify the locations of these objects
time python loadCSpace.py entities.csv collectionobject collectionobjects
time python loadCSpace.py entities.csv movement movements

# 4. load blobs, create MH records, relate to objects
# (the BMU is used to do this, and the user will have to have copied the code here to use)
if [ -e uploadMedia.py ]; then
  cut -f3 entities.csv | grep jpg > media.csv
  time python uploadMedia.py media.csv media.cfg
else
  echo "BMU not configured, please follow instructions"
fi

# move objects to locations
time python loadRelations.py entities.csv objects2locations

# fill in details in records
time python fillEntitles.py entities.csv

date

