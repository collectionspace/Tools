#!/bin/bash -x 
####
echo Loading Cluedo Museum...
date

# extract goodies to load from XML source file
python makeCSV.py cluedo.xml

# these are values for nightly.collectionspace.org
personauthorities=49d792ea-585b-4d38-b591
locationauthorities=2105d470-0d15-47e5-88ed

time python loadCSpace.py entities.csv person personauthorities $personauthorities
time python loadCSpace.py entities.csv storagelocation locationauthorities $locationauthorities
#time python loadCSpace.py entities.csv material conceptauthorites

time python loadCSpace.py entities.csv collectionobject collectionobjects
time python loadCSpace.py entities.csv movement movements

# load blobs, create MH records, relate to objects (i.e. BMU)
time python loadMedia.py entities.csv media

# move objects to locations
time python loadRelations.py entities.csv objects2locations

# fill in details in records
time python fillEntitles.py entities.csv

date

