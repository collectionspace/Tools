import csv
import sys

def getTMSlocations(locFile):

    try:
        locations = {}
        museumNumbers = {}
        #locs = csv.reader(codecs.open(locFile,'rb','utf-8'),delimiter="\t")
        locs = csv.reader(open(locFile,'rb'),delimiter="\t")
        for row,values in enumerate(locs):
            #print values
            loc = values[1]
            museumNumber = values[4].strip()
            #if loc == 'Kroeber, 20, W 33, 9': print values
            if not locations.has_key(loc): locations[loc] = []
            locations[loc].append(museumNumber)
            museumNumbers[museumNumber] = loc
        return locations,museumNumbers
    except:
        raise
        print 'log failed!'
        pass

def TMSlocation(locationsList,museumNumbers,location,museumNumber):

    try:
        return museumNumbers[museumNumber.strip()]
        if (museumNumber.strip() in locationsList[location]):
	    sys.stderr.write("tmscheck found: #%s# at #%s#" % (museumNumber,location))
            return True
        else:
	    sys.stderr.write("tmscheck did not find #%s# at #%s#" % (museumNumber,location))
            return False
    except:
        return 'Object not found in TMS'

if __name__ == "__main__":

    locations,museumNumbers = getTMSlocations('tms2.csv')
    print 'locations',len(locations.keys())
    print locations['Kroeber, 20, W 33, 9']
    print TMSlocation(locations,museumNumbers,'Kroeber, 20A, W 33,  9','9-2362')
