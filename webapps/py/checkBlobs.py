import csv
import sys
import codecs
import pgdb
import re

from PIL import Image
from PIL.ExifTags import TAGS
import ConfigParser

import time, datetime

from os import listdir, environ
from os.path import isfile, join


def getWidthHeight(img):
    return img.size


def getBits(img):
    if img.mode == '1':
        return 1
    elif img.mode == 'I' or img.mode == 'F':
        return 32
    else:
        return 8


def getSamples(img):
    if img.mode == 'RGB' or img.mode == 'YcbCr':
        return 3
    elif img.mode == 'RGBA' or img.mode == 'CMYK':
        return 4
    else:
        return 1


def getColorModel(img):
    if img.mode == '1':
        return "B/W"
    elif img.mode == 'L':
        return "Grayscale"
    elif img.mode == 'P':

        return 'palette color'
    if img.mode == 'RGB' or img.mode == 'YcbCr':
        return 'Color'
    elif img.mode == 'RGBA' or img.mode == 'CMYK':
        return 'Color'
    else:
        return img.mode


def getFormat(img):
    return img.format

#if cell == "PCD":
#	return "IMAG PAC"

def getCompression(img):
    try:
        cell = img.info['compression']
    except:
        return None
    if cell == 'tiff_lzw':
        return 'LZW'
    elif cell == 'group4':
        return 'CCITT Group 4'
    elif cell == "IMAG PAC":
        return "PCD"
    else:
        print "Unknown compression format:", cell


def getConfig(form):
    try:
        fileName = form.get('webapp') + '.cfg'
        config = ConfigParser.RawConfigParser()
        config.read(fileName)
        # test to see if it seems like it is really a config file
        updateType = config.get('info', 'updatetype')
        return config
    except:
        return False


class CleanlinesFile(file):
    def next(self):
        line = super(CleanlinesFile, self).next()
        return line.replace('\r', '').replace('\n', '') + '\n'


# following function taken from stackoverflow...thanks!
def get_exif(fn):
    ret = {}
    im = Image.open(fn)
    info = im._getexif()
    for tag, value in info.items():
        decoded = TAGS.get(tag, tag)
        ret[decoded] = value
    return ret


def getBlobsFromDB(config, startdate, enddate):
    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()

    query = """
    SELECT cc.id, cc.updatedat, b.name, c.data AS md5
    FROM collectionspace_core cc
      INNER JOIN blobs_common b
        ON (cc.id = b.id)
      INNER JOIN content c
        ON (c.name = 'Original_'||b.name)
    WHERE cc.updatedat between '%s'  AND '%s'
    """ % (startdate, enddate)

    try:
        objects.execute('set statement_timeout to 30000')
        objects.execute(query)
        records = []
        for r in objects.fetchall():
            tif = {}
            for i, dbfield in enumerate('blobcsid updatedat name md5'.split(' ')):
                tif[dbfield] = r[i]

            m = re.search(r'(..)(..)', tif['md5'])
            tif['fullpathtofile'] = "%s/nuxeo-server/data/binaries/data/%s/%s/%s" % (
            environ['CATALINA_HOME'], m.group(1), m.group(2), tif['md5'])

            records.append(tif)
        return records

    except pgdb.DatabaseError, e:
        sys.stderr.write('getBlobsFromDB error: %s\n' % e)
        sys.exit()
    except:
        sys.stderr.write("some other getBlobsFromDB error!\n")
        sys.exit()


def get_tifftags(fn, ret):
    #fp = open(fn, "rb")
    im = Image.open(fn) # open from file object
    #im.load() # make sure PIL has read the data

    #im = Image.open(fn)
    ret['format'] = im.format
    # The file format of the source file. For images created by the library itself
    # (via a factory function, or by running a method on an existing image), this attribute is set to None.  
    ret['mode'] = im.mode
    # Image mode. This is a string specifying the pixel format used by the image.
    # Typical values are "1", "L", "RGB", or "CMYK." See Concepts for a full list.
    ret['size'] = im.size
    # Image size, in pixels. The size is given as a 2-tuple (width, height).
    ret['palette'] = im.palette
    if im.mode == 'P': ret['palette'] = 'ImagePalette'
    # Colour palette table, if any. If mode is "P", this should be an instance of the ImagePalette class. Otherwise, it should be set to None.


    info = im.info
    for tag, value in info.items():
        ret[tag] = value

        #del im
        #fp.close()


def writeCsv(filename, items, writeheader):
    filehandle = codecs.open(filename, 'w', 'utf-8')
    writer = csv.writer(filehandle, delimiter='\t')
    writer.writerow(writeheader)
    for item in items:
        row = []
        for x in writeheader:
            if x in item.keys():
                cell = str(item[x])
                cell = cell.strip()
                cell = cell.replace('"', '')
                cell = cell.replace('\n', '')
                cell = cell.replace('\r', '')
            else:
                cell = ''
            row.append(cell)
        writer.writerow(row)
    filehandle.close()


def getRecords(rawFile):
    try:
        records = []
        f = CleanlinesFile(rawFile, 'rb')
        csvfile = csv.reader(f, delimiter="|")
        for row, values in enumerate(csvfile):
            records.append(values)
        return records, len(values)
    except:
        raise


def getBloblist(blobpath):
    #filelist = [ f for f in listdir(blobpath) if isfile(join(blobpath,f)) and ('.csv' in f or 'trace.log' in f) ]
    filelist = [f for f in listdir(blobpath) if isfile(join(blobpath, f))]
    records = []
    for f in sorted(filelist):
        tif = {}
        tif['name'] = f
        tif['fullpathtofile'] = join(blobpath, f)
        records.append(tif)
    count = len(records)
    return records, count


if __name__ == "__main__":

    if sys.argv[1] == 'db':
        try:
            #form = {'webapp': '/var/www/cgi-bin/' + sys.argv[2]}
            form = {'webapp': sys.argv[2]}
            config = getConfig(form)
        except:
            print "MEDIA: could not get configuration"
            sys.exit()
        startdate = sys.argv[3]
        enddate = sys.argv[4]
        outputFile = sys.argv[5]

        records = getBlobsFromDB(config, startdate, enddate)


    elif sys.argv[1] == 'dir':

        #print 'config',config
        blobpath = sys.argv[2]
        records, count = getBloblist(blobpath)
        print 'MEDIA: %s files found in directory %s' % (count, sys.argv[2])
        outputFile = sys.argv[3]

    else:
        print 'datasource must either "db" or "dir"'
        sys.exit()

    columns = 'name blobcsid size istiff updatedat format mode palette compression dpi fullpathtofile'.split(' ')
    outputfh = csv.writer(open(outputFile, 'wb'), delimiter="\t")
    outputfh.writerow(columns)

    for i, tif in enumerate(records):

        elapsedtimetotal = time.time()
        row = []
        try:
            #print "checking file", i, tif['fullpathtofile']
            get_tifftags(tif['fullpathtofile'], tif)
            if tif['format'] == 'TIFF':
                tif['istiff'] = True
            else:
                tif['istiff'] = False
        except:
            print "failed on file", i, tif['fullpathtofile']
            raise
            #tif['istiff'] = 'Error'
            #print '%s: no tiff data' % tif['name']

        for v1, v2 in enumerate(columns):
            try:
                row.append(tif[v2])
            except:
                row.append('')

        try:
            outputfh.writerow(row)
        except:
            print "MEDIA: failed to write data for file %s, %8.2f" % (tif['name'], (time.time() - elapsedtimetotal))




