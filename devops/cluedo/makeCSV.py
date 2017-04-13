import xml.etree.ElementTree as ET
import sys, csv

tree = ET.parse(sys.argv[1])
root = tree.getroot()

mapping = {
    'victim': 'person',
    'suspect': 'person',
    'floor': 'room',
    'weapon': 'object',
    'media': 'image'
}

cluedo2cspace = {
    'person': 'person',
    'room': 'storagelocation',
    'object': 'collectionobject'
}

relations = ['collectionobjects2storagelocations', 'collectionobjects2people']

cspaceCSV = csv.writer(open('entities.csv', 'wb'), delimiter='\t')
entities = {}
for cluedoElement, cspaceElement in mapping.items():
    print 'looking for Cluedo %s elements' % cluedoElement
    for e in root.findall('.//' + cluedoElement):
        for c in e.findall('.//' + cspaceElement):
            print '   ', cluedoElement, c.tag, c.text
            slug = c.text.replace('.', '').replace(' ', '')
            print '   ', 'media', c.tag, slug + '_Full.jpg'
            entities[c.text] = cluedo2cspace[c.tag]
            cspaceCSV.writerow([cluedo2cspace[c.tag], c.tag, c.text])
            cspaceCSV.writerow(['media', c.text, slug + '_Full.jpg'])


for locations in [entities[x] for x in entities.keys() if entities[x] == 'storagelocation']:
    for objects in [entities[x] for x in entities.keys() if entities[x] == 'object']:
        pass


