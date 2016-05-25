import csv
import hashlib
import math
import sys
import re

from dwc_mapping import dwc_mapping
inputcolumns = [ i[0] for i in dwc_mapping]
outputcolumns = [ i[1] for i in dwc_mapping]

# to run type: python dwcready.py 4solr.ucjeps.public.csv your.output.file

# change column assignments as necessary
accessionnumbercolumn = 2
blobcolumn = 59

staticvalues = [('institutionCode', 'UCJEPS'),
                ('basisOfRecord', 'PreservedSpecimen'),
                ('rights', 'https://creativecommons.org/licenses/by-nd/4.0/'),
                ('accessRights', 'http://ucjeps.berkeley.edu/termsofuse.html')
                ]

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
        for rownum,row in enumerate(reader):
            if rownum == 0:
                header = row
            try:
                parsednumber = re.match('([A-Z]+)([0-9]+)',row[accessionnumbercolumn])
                if not parsednumber.group(1) in ['UC', 'JEPS', 'GOD']:
                    #print 'skipping %s' % row[collectioncode]
                    continue
                collectioncode = parsednumber.group(1)
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

            verbatimelevation = '%s %s' % (elevation_s, elevationunit_s)
            verbatimelevation = verbatimelevation.strip()

            depth_s = row[39]
            depth_unit_s = row[42]

            verbatimdepth = '%s %s' % (depth_s, depth_unit_s)
            verbatimdepth = verbatimdepth.strip()

            coordinateuncertainty_f = row[28]
            coordinateuncertaintyunit_s = row[29]

            if coordinateuncertainty_f == "0":
                coordinateuncertainty_f = ''
            else:
                coordinateuncertainty_f = str(convertunits(coordinateuncertainty_f,coordinateuncertaintyunit_s))
                pass

            newrow = []
            for i,r in enumerate(row):
                if header[i] in inputcolumns:
                    newrow.append(r)

            newrow + [collectioncode, verbatimdepth, verbatimelevation, coordinateuncertainty_f, blobs]
            for columnname,columnvalue in staticvalues:
                newrow.append(columnvalue)
            writer.writerow(newrow)

            try:
                pass
            except:
                print 'problem!!!'
                print row
                sys.exit()