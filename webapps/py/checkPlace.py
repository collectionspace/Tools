#!/usr/bin/python

import sys

from cswaUtils import getConfig
import cswaGetAuthorityTree


config = getConfig({'webapp': 'pahma_Packinglist_Dev'})

place = sys.argv[1]
print 'place:', place
places = cswaGetAuthorityTree.getAuthority('places', 'Placeitem', place, config.get('connect', 'connect_string'))
if len(places) < 200:
    for placeitem in places:
        print placeitem
else:
    print place, ':', len(places)
