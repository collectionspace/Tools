import csv
import hashlib
import math
import sys
import re

# to run type: python dwcready.py 4solr.ucjeps.public.csv your.output.file

# change column assignments as necessary
collectioncode = 2
blobcolumn = 59

def convertunits(value,unit):
    try:
        value = float(value)
        if unit == 'feet':
            value = value * 0.3048
        return value
    except:
        return ''

with open(sys.argv[2], "wb") as out:
    writer = csv.writer(out, delimiter="\t")
    with open(sys.argv[1], "rb") as original:
        reader = csv.reader(original, delimiter="\t")
        for row in reader:
            try:
                parsednumber = re.match('([A-Z]+)([0-9]+)',row[collectioncode])
                if not parsednumber.group(1) in ['UC', 'JEPS', 'GOD']:
                    #print 'skipping %s' % row[collectioncode]
                    continue
            except:
                print row
                print 'could not parse, skipping!!!'
                continue

            blobs = row[blobcolumn].split(',')
            bloblist = []
            for b in blobs:
                bloblist.append('https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/%s/derivatives/OriginalJpeg/content' % b)
            blobs = '|'.join(bloblist)

            earlycollectiondate_dt = row[11]
            latestcollectiondate_dt = row[12]

            if latestcollectiondate_dt:
                eventDate = "%s/%s" % (earlycollectiondate_dt,latestcollectiondate_dt)
            else:
                eventDate = earlycollectiondate_dt

            elevation_s = row[17]
            elevationunit_s = row[20]

            elevation = '%s %s' % (elevation_s, elevationunit_s)
            elevation = elevation.strip()

            depth_s = row[39]
            depth_unit_s = row[42]

            depth = '%s %s' % (depth_s, depth_unit_s)
            depth = depth.strip()

            coordinateuncertainty_f = row[28]
            coordinateuncertaintyunit_s = row[29]

            if coordinateuncertainty_f == "0":
                coordinateuncertainty_f = ''
            else:
                coordinateuncertainty_f = str(convertunits(coordinateuncertainty_f,coordinateuncertaintyunit_s))
                pass

            writer.writerow(row)

            try:
                pass
            except:
                print 'problem!!!'
                print row
                sys.exit()
