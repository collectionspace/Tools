import xml.etree.ElementTree as ET
import sys, csv, re, os
from xml.sax.saxutils import escape
from cswaExtras import postxml

from constants import *

# TODO: this script does not work yet! scaffolding only here!

inputfile = sys.argv[1]

username = os.environ['LOGIN']
password = os.environ['PASSWORD']
server = os.environ['CSPACEURL']
realm = 'org.collectionspace.services'

def substitute(mh,payload):

    for m in mh.keys():
        payload = payload.replace('{%s}' % m, escape(mh[m]))

    # get rid of any unsubstituted items in the template
    payload = re.sub(r'\{.*?\}', '', payload)
    return payload

uri = 'collectionobjects'

cspaceCSVin  = csv.reader(open(inputfile, 'rb'), delimiter='\t')
cspaceCSVout = csv.writer(open('update.created.csv', 'wb'), delimiter='\t')

entities = {}

print '%s/%s' % (server, uri)

for row in cspaceCSVin:
    print row
    if row[0] == 'update':
        template = ''
        payload = substitute({'objectnumber': '99'},template)
        # (url, data, csid, elapsedtime) = postxml('POST', uri, realm, server, username, password, payload)
        csid = 'xxxx'
        row.append(csid)
        cspaceCSVout.writerow(row)


        