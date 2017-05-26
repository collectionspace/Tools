import xml.etree.ElementTree as ET
import sys, csv, re, os
from xml.sax.saxutils import escape
from cswaExtras import postxml, make_get_request

from constants import *

inputfile = sys.argv[1]
entity = sys.argv[2]
authority = sys.argv[3]

username = os.environ['LOGIN']
password = os.environ['PASSWORD']
server = os.environ['CSPACEURL']
realm = 'org.collectionspace.services'

xmlfile = 'xml/%s.xml' % authority
try:
    template = open(xmlfile).read()
except:
    print 'could not open template file %s' % xmlfile
    exit(1)

def substitute(mh,payload):

    for m in mh.keys():
        payload = payload.replace('{%s}' % m, escape(mh[m]))

    # get rid of any unsubstituted items in the template
    payload = re.sub(r'\{.*?\}', '', payload)
    return payload

# def findauthority(authority):
    # take in authority name, authority id, and __ in order to see the authority record that we need
    # get the xml for the auth csid, and parse to get the refname
    # tree = ET.parse(sys.argv[1])
    # root = tree.getroot()
    # return 'authoritycsid'


try:
    authoritycsid = sys.argv[4]
    if authoritycsid == '': raise
    uri = '%s/%s/items' % (authority, authoritycsid)
except:
    authoritycsid = ''
    uri = '%s' % authority

cspaceCSVin  = csv.reader(open(inputfile, 'rb'), delimiter='\t')
cspaceCSVout = csv.writer(open('%s.created.csv' % authority, 'wb'), delimiter='\t')

entities = {}

print '%s/%s' % (server, uri)

sequencenumber = 0
for row in cspaceCSVin:
    print row
    if row[0] == entity:
        sequencenumber += 1
        payload = substitute({'authority': authoritycsid, entity: row[2], 'sequencenumber': '%03d' % sequencenumber},template)
        (url, data, csid, elapsedtime) = postxml('POST', uri, realm, server, username, password, payload)
        
        get_uri = '%s/%s/items/%s' % (authority, authoritycsid, csid)
        (url, get_xml, scode) = make_get_request(realm, uri, server, username, password)
        # def make_get_request(realm, uri, hostname, protocol, port, username, password):

        tree = ET.fromstring(get_xml)
        refname = tree.find(".//refName").text
        

        row.append(csid)
        row.append(authoritycsid)
        row.append(refname)
        cspaceCSVout.writerow(row)


        