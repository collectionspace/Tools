import csv
import sys, os
import codecs
import ConfigParser
from copy import deepcopy
from xml.sax.saxutils import escape

import time, datetime
import httplib, urllib2
import cgi

import re

CONFIGDIRECTORY = ''


def getConfig(fileName):
    try:
        config = ConfigParser.RawConfigParser()
        config.read(fileName)
        # test to see if it seems like it is really a config file
        connect = config.get('connect', 'hostname')
        return config
    except:
        return False


def postxml(requestType, uri, realm, protocol, hostname, port, username, password, payload):
    data = None
    csid = ''

    if port != '':
        port = ':' + port
    server = protocol + "://" + hostname + port
    passman = urllib2.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passman)
    opener = urllib2.build_opener(authhandler)
    urllib2.install_opener(opener)
    url = "%s/cspace-services/%s" % (server, uri)

    elapsedtime = time.time()
    request = urllib2.Request(url, payload, {'Content-Type': 'application/xml'})
    # default method for urllib2 with payload is POST
    if requestType == 'PUT': request.get_method = lambda: 'PUT'
    try:
        f = urllib2.urlopen(request)
        data = f.read()
        info = f.info()
        # if a POST, the Location element contains the new CSID
        if info.getheader('Location'):
            csid = re.search(uri + '/(.*)', info.getheader('Location')).group(1)
        else:
            csid = ''
    except urllib2.HTTPError, e:
        sys.stderr.write('URL: ' + url + '\n')
        sys.stderr.write('PUT failed, HTTP code: ' + str(e.code) + '\n')
        print payload
        print data
        print info
        sys.stderr.write('Data: ' + data + '\n')
        raise
    except urllib2.URLError, e:
        sys.stderr.write('URL: ' + url + '\n')
        if hasattr(e, 'reason'):
            sys.stderr.write('We failed to reach a server.\n')
            sys.stderr.write('Reason: ' + str(e.reason) + '\n')
        if hasattr(e, 'code'):
            sys.stderr.write('The server couldn\'t fulfill the request.\n')
            sys.stderr.write('Error code: ' + str(e.code) + '\n')
        if True:
            # print 'Error in POSTing!'
            sys.stderr.write("Error in POSTing!\n")
            sys.stderr.write(payload)
            raise
    except:
        sys.stderr.write('Some other error' + '\n')
        raise

    elapsedtime = time.time() - elapsedtime
    return (url, data, csid, elapsedtime)


def createXMLpayload(template, values, institution):
    payload = deepcopy(template)
    for v in values.keys():
        payload = payload.replace('{' + v + '}', escape(values[v]))
    # get rid of remaining unsubstituted template variables
    payload = re.sub('(<.*?>){(.*)}(<.*>)', r'\1\3', payload)
    return payload


def fims2cspace(xmlTemplate, fimsDataDict, config):
    try:
        realm = config.get('connect', 'realm')
        hostname = config.get('connect', 'hostname')
        port = config.get('connect', 'port')
        protocol = config.get('connect', 'protocol')
        username = config.get('connect', 'username')
        password = config.get('connect', 'password')
        INSTITUTION = config.get('info', 'institution')
    except:
        print "could not get at least one of realm, hostname, username, password or institution from config file."
        # print "can't continue, exiting..."
        raise

    # objectCSID = getCSID('objectnumber', cspaceElements['objectnumber'], config)
    objectNumber = fimsDataDict['barcodenumber']
    if objectNumber == [] or objectNumber is None:
        print "could not get (i.e. find) objectnumber's csid: %s." % cspaceElements['objectnumber']
        # raise Exception("<span style='color:red'>Object Number not found: %s!</span>" % cspaceElements['objectnumber'])
    else:
        uri = 'collectionobjects'

        messages = []
        messages.append("posting to cspace REST API...")
        payload = createXMLpayload(xmlTemplate, fimsDataDict, INSTITUTION)
        # print payload
        (url, data, objectCSID, elapsedtime) = postxml('POST', uri, realm, protocol, hostname, port, username, password, payload)
        return [objectNumber, objectCSID]
        messages.append('got cspacecsid %s elapsedtime %s ' % (objectCSID, elapsedtime))
        messages.append("cspace REST API post succeeded...")

    return cspaceElements


class CleanlinesFile(file):
    def next(self):
        line = super(CleanlinesFile, self).next()
        return line.replace('\r', '').replace('\n', '') + '\n'


def getRecords(rawFile):
    # csvfile = csv.reader(codecs.open(rawFile,'rb','utf-8'),delimiter="\t")
    try:
        f = CleanlinesFile(rawFile, 'rb')
        csvfile = csv.reader(f, delimiter="\t")
    except IOError:
        message = 'Expected to be able to read %s, but it was not found or unreadable' % rawFile
        return message, -1
    except:
        raise

    try:
        rows = []
        records = {}
        for rowNumber, row in enumerate(csvfile):
            if not row[0]: continue
            if row[0][0] == "#": continue  # skip comments
            if not row[0] in records:
                records[row[0]] = {}
                records[row[0]]['bcid'] = row[0]
            records[row[0]][row[1]] = row[2]
            rows.append(row)
        return records, len(rows)
    except IOError:
        raise
        message = 'could not read (or maybe parse) rows from %s' % rawFile
        return message, -1
    except:
        raise


if __name__ == "__main__":

    header = "*" * 80

    if len(sys.argv) < 6:
        print('%s <FIMS input file> <config file> <mapping file> <template> <output file>') % sys.argv[0]
        sys.exit()

    print header
    print "FIMS2CSPACE: input  file:    %s" % sys.argv[1]
    print "FIMS2CSPACE: config file:    %s" % sys.argv[2]
    print "FIMS2CSPACE: mapping file:   %s" % sys.argv[3]
    print "FIMS2CSPACE: template:       %s" % sys.argv[4]
    print "FIMS2CSPACE: output file:    %s" % sys.argv[5]
    print header

    try:
        fimsRecords, lines = getRecords(sys.argv[1])
        print 'FIMS2CSPACE: %s lines and %s records found in file %s' % (lines, len(fimsRecords), sys.argv[1])
        print header
        if lines == -1:
            print 'FIMS2CSPACE: Error! %s' % fimsRecords
            sys.exit()
    except:
        print "FIMS2CSPACE: could not get FIMS records to load"
        sys.exit()

    try:
        config = getConfig(sys.argv[2])
        print "FIMS2CSPACE: hostname        %s" % config.get('connect', 'hostname')
        print "FIMS2CSPACE: institution     %s" % config.get('info', 'institution')
        print header
    except:
        print "FIMS2CSPACE: could not get cspace server configuration"
        sys.exit()

    try:
        mapping, numitems = getRecords(sys.argv[3])
        print 'FIMS2CSPACE: %s lines and %s records found in file %s' % (numitems, len(mapping), sys.argv[3])
        # print mapping
        print header
    except:
        print "FIMS2CSPACE: could not get mapping configuration"
        sys.exit()

    try:
        with open(sys.argv[4], 'rb') as f:
            xmlTemplate = f.read()
            # print xmlTemplate
    except:
        print "FIMS2CSPACE: could not get template"
        sys.exit()

    try:
        outputfh = csv.writer(open(sys.argv[5], 'wb'), delimiter="\t")
    except:
        print "FIMS2CSPACE: could not open output file for write %s" % sys.argv[5]
        sys.exit()

    successes = 0
    recordsprocessed = 0
    for bcid, fimsData in fimsRecords.items():

        elapsedtimetotal = time.time()
        try:
            cspaceElements = fims2cspace(xmlTemplate, fimsData, config)
            cspaceElements.append(time.time() - elapsedtimetotal)
            print "FIMS2CSPACE: objectnumber %s, objectcsid: %s %8.2f" % tuple(cspaceElements)
            if cspaceElements[1] != '':
                successes += 1
            outputfh.writerow(cspaceElements)
        except:
            print "FIMS2CSPACE: create failed for objectnumber %s, %8.2f" % (
                fimsData['barcodenumber'], (time.time() - elapsedtimetotal))
            # raise
        recordsprocessed += 1

    print header
    print "FIMS2CSPACE: %s records processed, %s successful PUTs" % (recordsprocessed, successes)
    print header