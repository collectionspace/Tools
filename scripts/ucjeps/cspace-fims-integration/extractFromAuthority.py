import xml.etree.ElementTree as ET
import sys, csv, codecs

reload(sys)
sys.setdefaultencoding('utf-8')

def extractTag(xml, tag):
    element = xml.find('.//%s' % tag)
    return element.text


cspaceXML = ET.parse(sys.argv[1])
root = cspaceXML.getroot()
items = cspaceXML.findall('.//list-item')

cspaceCSV = csv.writer(codecs.open(sys.argv[2], 'w', "utf-8"), delimiter='\t')
entities = {}

numberofitems = len(items)
# if numberofitems > numberWanted:
#    items = items[:numberWanted]

sequence_number = 0
for i in items:
    sequence_number += 1
    csid = i.find('.//csid')
    csid = csid.text
    termDisplayName = extractTag(i, 'termDisplayName')
    refName = extractTag(i, 'refName')
    updated_at = extractTag(i, 'updatedAt')
    cspaceCSV.writerow([sequence_number, csid, termDisplayName, refName, updated_at])
