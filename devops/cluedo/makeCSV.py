import xml.etree.ElementTree as ET
import sys, csv

tree = ET.parse(sys.argv[1])
root = tree.getroot()

mapping = {'persons': ['victim', 'suspect'], 'storagelocations': ['room'], 'collectionobjects': ['weapon'],
           'media': ['image']}

relations = ['collectionobjects2storagelocations', 'collectionobjects2people']

for xenoElements in mapping.items():
    cspaceElement = xenoElements[0]
    cspaceCSV = csv.writer(open(cspaceElement + '.csv', "wb"), delimiter='\t')
    for xenoElement in xenoElements[1]:
        for xenoInstance in root.iter(xenoElement):
            print cspaceElement, xenoInstance.tag, xenoInstance.text
            cspaceCSV.writerow([xenoInstance.tag, xenoInstance.text])
