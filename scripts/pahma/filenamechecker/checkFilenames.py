import csv
import sys
import time
import re

from cswaExtras import getConfig, getCSID

objectnumberpattern = re.compile('([a-z]+)\.([a-zA-Z0-9]+)')

def getNumber(filename):
    imagenumber = ''
    # the following is only for bampfa filenames...
    # input is something like: bampfa_1995-46-194-a-199.jpg, output should be: 1995.46.194.a-199
    if 'bampfa_' in filename:
        objectnumber = filename.replace('bampfa_', '')
        try:
            objectnumber, imagenumber, imagetype = objectnumber.split('_')
        except:
            imagenumber = '1'
        # these legacy statement retained, just in case...
        # numHyphens = objectnumber.count("-") - 1
        # objectnumber = objectnumber.replace('-', '.', numHyphens)
        objectnumber = objectnumber.replace('-', '.')
        objectnumber = objectnumberpattern.sub(r'\1-\2', objectnumber)
    # for non-bampfa users (i.e. pahma, at the moment) it suffices to split on underscore...
    else:
        objectnumber = filename
        objectnumber = objectnumber.split('_')[0]
    # the following is a last ditch attempt to get an object number from a filename...
    objectnumber = objectnumber.replace('.JPG', '').replace('.jpg', '').replace('.TIF', '').replace('.tif', '')
    return filename, objectnumber, imagenumber


def objectfromfilename(filename, config):
    filenamex, objectnumber, imagenumber = getNumber(filename)
    objectCSID = getCSID('objectnumber', objectnumber, config)

    if objectCSID is None:
        #print "could not get (i.e. find) objectnumber's csid: %s." % objectnumber
        objectCSID = ''
    else:
        objectCSID = objectCSID[0]
    return [filename, objectnumber, objectCSID]


class CleanlinesFile(file):
    def next(self):
        line = super(CleanlinesFile, self).next()
        return line.replace('\r', '').replace('\n', '') + '\n'


def getRecords(rawFile):
    try:
        f = CleanlinesFile(rawFile, 'rb')
        csvfile = csv.reader(f, delimiter=",")
    except IOError:
        message = 'Expected to be able to read %s, but it was not found or unreadable' % rawFile
        return message, -1
    except:
        raise

    try:
        records = []
        for row, values in enumerate(csvfile):
            records.append(values)
        return records, len(values)
    except IOError:
        message = 'Could not read (or maybe parse) rows from %s' % rawFile
        return message, -1
    except:
        raise


if __name__ == "__main__":

    if len(sys.argv) != 5:
        print "MEDIA: %s inputfile.csv configfile.cfg outputfile.csv column" % sys.argv[0]
        sys.exit()

    print "MEDIA: config file: %s" % sys.argv[2]
    print "MEDIA: input  file: %s" % sys.argv[1]
    print "MEDIA: output file: %s" % sys.argv[3]
    print "MEDIA: column:      %s" % sys.argv[4]

    try:
        column = int(sys.argv[4])
    except:
        print "MEDIA: column value not a integer"
        sys.exit()

    try:
        form = {'webapp': sys.argv[2]}
        config = getConfig(form)
    except:
        print "MEDIA: could not get configuration"
        sys.exit()

    records, columns = getRecords(sys.argv[1])
    if columns == -1:
        print 'MEDIA: Error! %s' % records
        sys.exit()

    print 'MEDIA: %s columns and %s lines found in file %s' % (columns, len(records), sys.argv[1])
    outputFile = sys.argv[3]
    outputfh = csv.writer(open(outputFile, 'wb'), delimiter="\t")

    counts = [0,0, 0]
    for i, r in enumerate(records):
        elapsedtimetotal = time.time()
        mediaElements = objectfromfilename(r[column], config)
        # count 'successes'
        if mediaElements[2] != '':
            counts[0] += 1
        else:
            counts[1] += 1
        counts[2] += 1
        outputfh.writerow(mediaElements)

    print "CSID found %s \nCSID not found %s \nLines output %s \n" % tuple(counts)

