#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""originally this was parseNamesGBIF.py

"Use the GBIF name parser API (http://tools.gbif.org/nameparser/api.do) to
disect [sic] name strings into their components. Input should be a simple list of
name strings separated by newline-characters. The names can be read either
from textfile(s) or from <STDIN>.

Output will be written as JSON to <STDOUT> by default.

Usage: parseNamesGBIF.py filename1 [filename2 [...]]

from:

https://www.snip2code.com/Snippet/162694/Parse-taxon-names-with-Python--using-the"

However, I have hacked it substantially for this UCBG application, and it now takes three command line arguments,
caches the results, etc. etc.

... jblowe@berkeley.edu 4/6/2015

"""

import fileinput
import pickle
import requests
import re
import sys
import json
import time
import os
# import csv
import codecs

# empty class for counts
class count:
    pass


count.input = 0
count.output = 0
count.newnames = 0
count.source = 0
count.datasource = 0
count.cultivars = 0
count.cultivarsinoriginal = 0

parts = {}

nameparts = ["authorsParsed",
             "authorship",
             "bracketAuthorship",
             "canonicalName",
             "canonicalNameComplete",
             "canonicalNameWithMarker",
             "genusOrAbove",
             "infraSpecificEpithet",
             "rankMarker",
             "scientificName",
             "specificEpithet",
             "type"]

# from http://stackoverflow.com/questions/1158076/implement-touch-using-python
def touch(fname, times=None):
    with open(fname, 'a'):
        os.utime(fname, times)

# look for cultivars, e.g. "Ceanothus 'Berkeley Skies'", make it Ceanothus cv. Berkeley Skies for GBIF parsing"
cultivarpattern = re.compile("(.*)'(.*)'")


def check4cultivars(name):
    return name
    # the following code is now defunct
    # if not 'cv.' in name:
    #     name = cultivarpattern.sub(r'\1 cv. \2', name)
    # else:
    #     count.cultivarsinoriginal += 1
    # if 'cv.' in name: count.cultivars += 1
    # return name


def main():
    if len(sys.argv) < 4:
        print 'usage: %s inputfileofnames.csv outputnameparts.csv picklefile column' % sys.argv[0]
        sys.exit(1)

    namecolumn = 0
    try:
        namecolumn = int(sys.argv[4])
    except:
        print "column is not an integer: %s " % sys.argv[4]
        sys.exit(1)

    try:
        namepartsfile = sys.argv[2]
        # namepartsfh = csv.writer(open(namepartsfile, "wb"), delimiter='\t')
        namepartsfh = open(namepartsfile, "wb")
        #namepartsfh.write('\t'.join(nameparts) + '\n')
    except:
        print "could not open output file"
        sys.exit(1)

    try:
        picklefile = sys.argv[3]
        picklefh = open(picklefile, "rb")
    except:
        print "could not open pickle file, will try to create"
        picklefh = open(picklefile, "wb")
        pickle.dump({}, picklefh)
        picklefh.close()
        picklefh = open(picklefile, "rb")

    try:
        parsednames = pickle.load(picklefh)
        picklefh.close()
        print "%s names in datasource." % len(parsednames.keys())
    except:
        raise
        print "could not parse data in picklefile %s" % picklefile
        sys.exit(1)

    try:
        inputfile = codecs.open(sys.argv[1], "rb", "utf-8")
    except:
        raise
        print "could not open input file %s" % sys.argv[1]
        sys.exit(1)

    for line in inputfile:
        count.input += 1
        inputrow = line.rstrip('\n')
        cells = inputrow.split('\t')
        name = cells[namecolumn]
        # handle cultivars without 'cv.'...
        name = check4cultivars(name)
        if name in parsednames:
            count.source += 1
            name2use = parsednames[name]
        else:
            time.sleep(1)  # delays for 1 second
            response = requests.get('http://api.gbif.org/v1/parser/name', params={'name': name})
            response.encoding = 'utf-8'
            name2use = response.json()[0]
            count.newnames += 1
            parsednames[name] = name2use

        row = []

        for part in name2use.keys():
            parts[part] = parts.get(part, 0) + 1

        for part in nameparts:
            if part in name2use:
                try:
                    row.append(name2use[part].encode('utf-8'))
                except:
                    row.append(str(name2use[part]))
            else:
                row.append('')

        if count.input == 1:
            row = [h + '_s' for h in nameparts]
        cells = [x.encode('utf-8') for x in cells]
        cells = cells[:namecolumn] + row + cells[namecolumn:]
        namepartsfh.write('\t'.join(cells) + '\n')

    try:
        pickle.dump(parsednames, open(picklefile, "wb"))
        count.datasource = len(parsednames.keys())
    except:
        print "could not write names to picklefile %s" % picklefile
        sys.exit(1)

    print "%s names input." % count.input
    print "%s parsenames output." % count.output
    print "%s new names found." % count.newnames
    print "%s names now in datasource." % count.datasource
    print "%s cultivars indicated already (i.e 'cv.' in original)." % count.cultivarsinoriginal
    print "%s total cultivars identified." % count.cultivars

    print
    print 'name parts:'
    for p in parts.keys():
        print "%s: %s" % (p, parts[p])


if __name__ == '__main__':
    main()

