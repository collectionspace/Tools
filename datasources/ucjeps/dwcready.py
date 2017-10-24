import csv
import hashlib
import math
import sys
import re

from dwc_mapping import *

# these input fields need to be created or massaged to be DWC-compatible
specialhandling = 'collectionCode,eventDate,verbatimDepth,verbatimElevation,coordinateUncertaintyInMeters,associatedMedia'.split(',')

dwc_mapping = [d for d in dwc_mapping if d[1] not in specialhandling]

inputcolumns = [ i[0] for i in dwc_mapping if i[1] != 'tbd']
outputcolumns = [ i[1] for i in dwc_mapping if i[1] != 'tbd']

# to run type: python dwcready.py 4solr.ucjeps.public.csv your.output.file

staticvalues = [('institutionCode', 'UCJEPS'),
                ('basisOfRecord', 'PreservedSpecimen'),
                ('rights', 'https://creativecommons.org/licenses/by-nd/4.0/'),
                ('accessRights', 'http://ucjeps.berkeley.edu/termsofuse.html')
                ]

# make the output header, a bit complicated as the columns come from different sources
def makeheader(staticvalues, specialhanding, inputcolumns, outputcolumns, header):
    newheader = []
    for i, cell in enumerate(header):
        if cell in inputcolumns:
            x = inputcolumns.index(cell)
            newheader.append(outputcolumns[x])
    newheader += specialhanding
    [newheader.append(s[0]) for s in staticvalues]
    return newheader

def convertunits(value,unit):
    try:
        value = float(value)
        if unit == 'feet':
            value = value * 0.3048
        return value
    except:
        return ''

with open(sys.argv[2], "wb") as csvoutput:
    writer = csv.writer(csvoutput, delimiter="\t")
    with open(sys.argv[1], "rb") as original:
        reader = csv.reader(original, delimiter="\t")
        try:
            for rownum,row in enumerate(reader):
                if rownum == 0:
                    header = row
                    writer.writerow(makeheader(staticvalues, specialhandling, inputcolumns, outputcolumns, header))
                    continue
                else:
                    try:
                        parsednumber = re.match('([A-Z]+)([0-9]+)',row[accessionnumber_column])
                        if not parsednumber.group(1) in ['UC', 'JEPS', 'GOD']:
                            #print 'skipping %s' % row[collectioncode]
                            continue
                        collectioncode = parsednumber.group(1)
                    except:
                        print row
                        print 'could not parse accessionnumber, skipping!!!'
                        continue

                blobs = row[blob_column].split(',')
                bloblist = []
                for b in blobs:
                    bloblist.append('https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/%s/derivatives/OriginalJpeg/content' % b)
                blobs = '|'.join(bloblist)

                earlycollectiondate_dt = row[earlycollectiondate_column]
                latestcollectiondate_dt = row[latecollectiondate_column]

                if latestcollectiondate_dt:
                    eventDate = "%s/%s" % (earlycollectiondate_dt,latestcollectiondate_dt)
                else:
                    eventDate = earlycollectiondate_dt

                elevation_s = row[elevation_column]
                elevationunit_s = row[elevationunit_column]

                verbatimelevation = '%s %s' % (elevation_s, elevationunit_s)
                verbatimelevation = verbatimelevation.strip()

                depth_s = row[depth_column]
                depth_unit_s = row[depthunit_column]

                verbatimdepth = '%s %s' % (depth_s, depth_unit_s)
                verbatimdepth = verbatimdepth.strip()

                coordinateuncertainty_f = row[coordinateuncertainty_column]
                coordinateuncertaintyunit_s = row[coordinateuncertaintyunit_column]

                if coordinateuncertainty_f == "0":
                    coordinateuncertainty_f = ''
                else:
                    coordinateuncertainty_f = str(convertunits(coordinateuncertainty_f,coordinateuncertaintyunit_s))

                newrow = []
                for i,cell in enumerate(row):
                    if header[i] in inputcolumns:
                        newrow.append(cell)
                #collectionCode,eventDate,verbatimDepth,verbatimElevation,coordinateUncertaintyInMeters,associatedMedia
                newrow += [collectioncode, eventDate, verbatimdepth, verbatimelevation, coordinateuncertainty_f, blobs]
                for columnname,columnvalue in staticvalues:
                    newrow.append(columnvalue)
                writer.writerow(newrow)

        except:
            print 'problem with row %s!!!' % rownum
            print row