#!/bin/bash -x 
####
echo Loading Cluedo Museum...
date

# extract goodies to load from XML source file
python makeCSV.py cluedo.xml

# these are values for nightly.collectionspace.org
personauthorities=49d792ea-585b-4d38-b591
locationauthorities=2105d470-0d15-47e5-88ed

time python loadCSpace.py $1 person personauthorities $personauthorities
time python loadCSpace.py $1 storagelocation locationauthorities $locationauthorities
#time python loadCSpace.py $1 material conceptauthorites

time python loadCSpace.py $1 collectionobject collectionobjects
time python loadCSpace.py $1 movement movements

# load blobs, create MH records, relate to objects (i.e. BMU)
time python loadMedia.py $1 media

# move objects to locations
time python loadRelations.py $1 objects2locations

# fill in details in records
time python fillEntitles.py $1

date

