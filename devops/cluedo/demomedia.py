import csv
import sys
import re
import requests
from requests.auth import HTTPBasicAuth
import time
from os import path
from xml.sax.saxutils import escape
import traceback

from cswaExtras import make_request,relationsPayload, getConfig, getCSID

# NB: this is set in utils, but we cannot import that Django module in this ordinary script due to dependencies
FIELDS2WRITE = 'name size objectnumber date creator contributor rightsholder imagenumber handling approvedforweb'.split(' ')


def mediaPayload(mh, institution):
    payload = """<?xml version="1.0" encoding="UTF-8"?>
<document name="media">
<ns2:media_common xmlns:ns2="http://collectionspace.org/services/media" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<blobCsid>{blobCSID}</blobCsid>
<dateGroupList>
<dateGroup>
<dateDisplayDate>{date}</dateDisplayDate>
</dateGroup>
</dateGroupList>
<rightsHolder>{rightsholder}</rightsHolder>
<creator>{creator}</creator>
<title>{filename}</title>
<description>{description}</description>
<contributor>{contributor}</contributor>
<languageList>
<language>urn:cspace:INSTITUTION.cspace.berkeley.edu:vocabularies:name(languages):item:name(eng)'English'</language>
</languageList>
<identificationNumber>{objectnumber}</identificationNumber>
<typeList>
<type>{imagetype}</type>
</typeList>
<source>{source}</source>
<copyrightStatement>{copyright}</copyrightStatement>
</ns2:media_common>
<ns2:media_INSTITUTION xmlns:ns2="http://collectionspace.org/services/media/local/INSTITUTION" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<approvedForWeb>{approvedforweb}</approvedForWeb>
<primaryDisplay>false</primaryDisplay>
#IMAGENUMBERELEMENT#
#LOCALITY#
</ns2:media_INSTITUTION>
</document>
"""

    # xml-escape everything...
    for m in mh:
        mh[m] = escape(mh[m])

    for m in mh:
        payload = payload.replace('{%s}' % m, mh[m])

    # get rid of any unsubstituted items in the template
    payload = re.sub(r'\{.*?\}', '', payload)

    # institution specific hacks! figure out the right way to handle this someday!
    # if institution == 'bampfa':
    #     if 'imagenumber' in mh:
    #         payload = payload.replace('#IMAGENUMBERELEMENT#', '<imageNumber>%s</imageNumber>' % mh['imagenumber'])
    #
    # elif institution == 'botgarden':
    #     if 'imagenumber' in mh:
    #         # non-integer image numbers are an error for this tenant
    #         int(mh['imagenumber'])
    #         payload = payload.replace('#IMAGENUMBERELEMENT#', '<imageNumber>%s</imageNumber>' % mh['imagenumber'])
    #     payload = payload.replace('<primaryDisplay>false</primaryDisplay>', '')
    #     payload = payload.replace('<approvedForWeb>true</approvedForWeb>','<postToPublic>yes</postToPublic>')
    #     payload = payload.replace('<approvedForWeb>false</approvedForWeb>','<postToPublic>no</postToPublic>')
    #
    # elif institution == 'cinefiles':
    #     if 'imagenumber' in mh:
    #         payload = payload.replace('#IMAGENUMBERELEMENT#', '<page>%s</page>' % mh['imagenumber'])
    #
    # elif institution == 'ucjeps':
    #     payload = payload.replace('<approvedForWeb>true</approvedForWeb>','<postToPublic>yes</postToPublic>')
    #     payload = payload.replace('<approvedForWeb>false</approvedForWeb>','<postToPublic>no</postToPublic>')
    #     if 'locality' in mh:
    #         payload = payload.replace('#LOCALITY#',
    #                                   '''<localityGroupList><localityGroup>
    #                                   <fieldLocVerbatim>%s</fieldLocVerbatim>
    #                                   </localityGroup></localityGroupList>''' % mh['locality'])
            # payload = payload.replace('#LOCALITY#', '<locality>%s</locality>' % mh['locality'])

    # clean up anything that might be left
    payload = payload.replace('#IMAGENUMBERELEMENT#', '')
    payload = payload.replace('#LOCALITY#', '')
    payload = payload.replace('INSTITUTION', institution)

    # print "mediaPayload..."
    # print payload
    return payload

def uploadblob(mediaElements, config, http_parms):
    url = "%s/cspace-services/%s" % (http_parms.server, 'blobs')
    mediaElements['blobCSID'] = ''
    filename = mediaElements['name']
    fullpath = path.join(http_parms.cache_path, filename)
    payload = {'submit': 'OK'}
    #files = {'file': (filename, open(fullpath, 'rb'), 'image/jpeg')}
    files = {'file': (filename, open(fullpath, 'rb'))}

    response = requests.post(url, data=payload, files=files, auth=HTTPBasicAuth(http_parms.username, http_parms.password))
    if response.status_code != 201:
        print "blob creation failed!"
        print "response: %s" % response.status_code
        print response.content
    response.raise_for_status()

    blobURL = response.headers['location']
    blobCSID = blobURL.split('/')[-1:][0]
    mediaElements['blobCSID'] = blobCSID
    return mediaElements


def uploadmedia(mediaElements, config, http_parms):

    if 'blobCSID' in mediaElements:

        uri = 'media'

        messages = []
        messages.append("posting to media REST API...")
        payload = mediaPayload(mediaElements, http_parms.institution)
        elapsedtime = time.time()
        (url, data, mediaCSID) = make_request('POST', uri, http_parms.realm, http_parms.server, http_parms.username, http_parms.password, payload)
        elapsedtime = time.time() - elapsedtime
        messages.append('got mediacsid %s elapsedtime %s ' % (mediaCSID, elapsedtime))
        mediaElements['mediaCSID'] = mediaCSID
        messages.append("media REST API post succeeded...")
        # # for PAHMA, each uploaded image becomes the primary
        # if http_parms.institution == 'pahma':
        #     primary_payload = """<?xml version="1.0" encoding="utf-8" standalone="yes"?>
        #     <ns2:invocationContext xmlns:ns2="http://collectionspace.org/services/common/invocable"
        #     <mode>single</mode>
        #     <docType>""" + mediaCSID + """</docType>
        #     <singleCSID></singleCSID>
        #     </ns2:invocationContext>
        #    """
        #
        #     try:
        #         make_request('POST', 'batch/563d0999-d29e-4888-b58d', http_parms.realm, http_parms.server, http_parms.username, http_parms.password, primary_payload)
        #     except:
        #         print "batch job to set primary image failed."
        #
        # else:
        #     pass

        # are we supposed to try to link this media record to a collectionobject?
        if mediaElements['handling'] in 'slide borndigital mediaonly'.split(' '):
            mediaElements['objectCSID'] = 'N/A: %s' % mediaElements['handling']
        else:
            # try to relate media record to collection object if needed
            objectCSID, msg = getCSID('objectnumber', mediaElements['objectnumber'], http_parms)
            if objectCSID == [] or objectCSID is None:
                print "could not get (i.e. find) objectnumber's csid: %s." % mediaElements['objectnumber']
                mediaElements['objectCSID'] = 'not found'
                # raise Exception("<span style='color:red'>Object Number not found: %s!</span>" % mediaElements['objectnumber'])
            else:
                mediaElements['objectCSID'] = objectCSID

                uri = 'relations'

                messages.append("posting media2obj to relations REST API...")

                mediaElements['objectCsid'] = objectCSID
                mediaElements['subjectCsid'] = mediaCSID
                # "urn:cspace:institution.cspace.berkeley.edu:media:id(%s)" % mediaCSID

                mediaElements['objectDocumentType'] = 'CollectionObject'
                mediaElements['subjectDocumentType'] = 'Media'

                payload = relationsPayload(mediaElements)
                (url, data, csid) = make_request('POST', uri, http_parms.realm, http_parms.server, http_parms.username, http_parms.password, payload)
                # elapsedtimetotal += elapsedtime
                messages.append('got relation csid %s' % csid)
                mediaElements['media2objCSID'] = csid
                messages.append("relations REST API post succeeded...")

                # reverse the roles
                messages.append("posting obj2media to relations REST API...")
                temp = mediaElements['objectCsid']
                mediaElements['objectCsid'] = mediaElements['subjectCsid']
                mediaElements['subjectCsid'] = temp
                mediaElements['objectDocumentType'] = 'Media'
                mediaElements['subjectDocumentType'] = 'CollectionObject'
                payload = relationsPayload(mediaElements)
                (url, data, csid) = make_request('POST', uri, http_parms.realm, http_parms.server, http_parms.username, http_parms.password, payload)
                #elapsedtimetotal += elapsedtime
                messages.append('got relation csid %s' % csid)
                mediaElements['obj2mediaCSID'] = csid
                messages.append("relations REST API post succeeded...")

    return mediaElements


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

    if len(sys.argv) == 3:
        print "MEDIA: input  file (fully qualified path): %s" % sys.argv[1]
        print "MEDIA: config file (fully qualified path): %s" % sys.argv[2]
    else:
        print
        print "usage: %s <jobname> <config file>" % sys.argv[0]
        print "e.g.   %s 2017-02-05 pahma_Uploadmedia_dev.cfg" % sys.argv[0]
        print
        sys.exit(1)

    try:
        config = getConfig(sys.argv[2])
        if not config:
            raise
    except:
        print "MEDIA: could not get configuration from %s" % sys.argv[2]
        sys.exit(1)

    class http_parms:
        pass

    try:
        http_parms.realm = config.get('connect', 'realm')
        http_parms.hostname = config.get('connect', 'hostname')
        http_parms.port = config.get('connect', 'port')
        http_parms.protocol = config.get('connect', 'protocol')
        http_parms.username = config.get('connect', 'username')
        http_parms.password = config.get('connect', 'password')
        http_parms.institution = config.get('info', 'institution')
        http_parms.alwayscreatemedia = config.get('info', 'alwayscreatemedia')
        http_parms.alwayscreatemedia = True if http_parms.alwayscreatemedia.lower() == 'true' else False

        http_parms.server = http_parms.protocol + "://" + http_parms.hostname
        try:
            int(http_parms.port)
            http_parms.server = http_parms.server  + ':' + http_parms.port
        except:
            pass

        http_parms.cache_path = config.get('files', 'directory')

    except:
        print "could not get at least one of alwayscreatemedia, realm, hostname, port, protocol, username, password or institution from config file."
        # print "can't continue, exiting..."
        sys.exit(1)

    # print 'config',config
    records, columns = getRecords(sys.argv[1])
    if columns == -1:
        print 'MEDIA: Error! %s' % records
        sys.exit()

    print 'MEDIA: %s columns and %s lines found in file %s' % (columns, len(records), sys.argv[1])
    outputFile = sys.argv[1].replace('.csv', '.created.csv')
    outputfh = csv.writer(open(outputFile, 'wb'), delimiter="\t")

    # the first row of the file is a header
    columns = records[0]
    del records[0]
    outputfh.writerow(columns + ['mediaCSID', 'objectCSID', 'blobCSID'])

    for i, r in enumerate(records):

        elapsedtimetotal = time.time()
        mediaElements = {}
        # ensure that all the possible fields have keys in this dict
        for v in FIELDS2WRITE:
            mediaElements[v] = ''
        # now insert the actual values for those that appear in the input
        for v1, v2 in enumerate(columns):
            mediaElements[v2] = r[v1]
        mediaElements['approvedforweb'] = 'true' if mediaElements['approvedforweb'] == 'on' else 'false'
        print 'MEDIA: uploading media for filename %s, objectnumber: %s' % (mediaElements['name'], mediaElements['objectnumber'])
        try:
            mediaElements = uploadblob(mediaElements, config, http_parms)
            mediaElements = uploadmedia(mediaElements, config, http_parms)
            print "MEDIA: objectnumber %s, objectcsid: %s, mediacsid: %s, %8.2f" % (
                mediaElements['objectnumber'], mediaElements['objectCSID'], mediaElements['mediaCSID'],
                (time.time() - elapsedtimetotal))
            r.append(mediaElements['mediaCSID'])
            r.append(mediaElements['objectCSID'])
            r.append(mediaElements['blobCSID'])
            outputfh.writerow(r)
        except:
            print "%s" % traceback.format_exc()
            print "MEDIA: create failed for blob or media. objectnumber %s, %8.2f" % (
                mediaElements['objectnumber'], (time.time() - elapsedtimetotal))
            # delete the blob if we did not manage to make a media record for it...
            try:
                (url, data, deletedCSID, elapsedtime) = make_request('DELETE', 'blobs/%s' % mediaElements['blobCSID'], http_parms.realm, http_parms.server, http_parms.username,
                                                          http_parms.password, '')
                print "MEDIA: deleted blob %s" % mediaElements['blobCSID']
            except:
                print "MEDIA: failed to delete blob %s" % mediaElements['blobCSID']