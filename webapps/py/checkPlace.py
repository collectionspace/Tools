#!/usr/bin/python

import sys
import cswaGetPlaces

p = sys.argv[1]
print 'p:', p
places = cswaGetPlaces.getPlaces(p)
if len(places) < 200:
    for place in places:
        print place
else:
    print p, ':', len(places)
