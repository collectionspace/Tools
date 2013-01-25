#!/usr/bin/env /usr/bin/python

import os
import sys

# for log
import csv
import codecs
import ConfigParser

import time, datetime
import httplib, urllib2
import cgi
#import cgitb; cgitb.enable()  # for troubleshooting
import re
from lxml import etree

# the only other module: isolate postgres calls and connection
import cswaDB
import getPlaces
import getTaxname

def getConfig(form):

   try:
       fileName = form.getvalue('webapp') + '.cfg'
       config = ConfigParser.RawConfigParser()
       config.read(fileName)
       return config
   except:
       return False

def handleTimeout(source,form):
    print '<h3><span style="color:red;">Time limit exceeded! The problem has been logged and will be examined. Feel free to try again though!</span></h3>'
    sys.stderr.write('TIMEOUT::'+source+'::location::'+str(form.getvalue("lo.location1"))+'::')

def validateParameters(form,config):

    valid = True

    if form.getvalue('handlerRefName') == 'None':
        print '<h3>Please select a handler before searching</h3>'
        valid = False

    #if not str(form.getvalue('num2ret')).isdigit():
    #    print '<h3><i>number to retrieve</i> must be a number, please!</h3>'
    #    valid = False

    if form.getvalue('reason') == 'None':
        print '<h3>Please select a reason before searching</h3>'
        valid = False

    if config.get('info','updatetype') == 'barcodeprint':
        if form.getvalue('printer') == 'None':
            print '<h3>Please select a printer before trying to print labels</h3>'
            valid = False

    return valid

def search(form,config):

    mapping = { 'lo.location1' : 'l1', 'lo.location2' : 'l2', 'ob.objectnumber' : 'ob', 'cp.place' : 'pl', 'co.concept' : 'co' }
    for m in mapping.keys():
        if form.getvalue(m) == None:
	    pass
	else:
	    print '%s : %s %s\n' % (m,mapping[m],form.getvalue(m))


def doSearch(form,config):

    if not validateParameters(form,config): return

    try:
        rows = cswaDB.getloclist('range',form.getvalue("lo.location1"),form.getvalue("lo.location2"),20000,config)
        rowcount = len(rows)
        print """
    <table width="100%%">
    <tr>
      <th>%s locations in this range</th>
    </tr>""" % rowcount
        locations = {}
        for r in rows:
            print formatRow( { 'rowtype':'location','data': r },form,config )

        print "\n</table><hr/>"
        print """<input type="hidden" name="count" value="%s">""" % rowcount
    except:
	raise
        handleTimeout('search',form)

def countLocations(form,config):

    if not validateParameters(form,config): return

    try:
        rows = cswaDB.getloclist('range',form.getvalue("lo.location1"),form.getvalue("lo.location2"),20000,config)
    except:
        raise
        handleTimeout('search',form)

    rowcount = len(rows)
    print """
    <table width="100%%">
    <tr>
      <th>%s locations in this range</th><th/>
    </tr>""" % rowcount
    if rowcount == 0:
	return

    print '<tr><th>first location</th><td class="locations">',rows[0][0],'</td></tr>'
    print '<tr><th>last location</th><td class="locations">',rows[-1][0],'</td></tr>'

    print """<tr><td align="center" colspan="2"><hr><td></tr>"""
    print """<tr><td align="center">"""
    msg = config.get('info','updateactionlabel')
    print """<input type="submit" class="save" value="%s" name="action"></td>""" % msg
    if updateType == 'inventory':    doSearch(form,config)
    if config.get('info','updatetype') == "packinglist":
        print """<td><input type="submit" class="save" value="%s" name="action"></td>""" % 'Download as CSV'
    else:
	print "<td></td>"
    print "\n</tr></table><hr/>"
    print """<input type="hidden" name="count" value="%s">""" % rowcount

def countTaxa(form,config):

    #if not validateParameters(form,config): return

    taxName = form.getvalue("ta.taxon")
    try:
        rows = getTaxname.getTaxon(taxName)
    except:
        raise
        handleTimeout('countTaxa',form)

    rowcount = len(rows)
    print """
    <table width="100%%">
    <tr>
      <th>%s taxonomic names under this taxon</th><th/>
    </tr>""" % rowcount
    if rowcount == 0:
	return

    #rows.sort()
    for r in rows:
       print '<tr><td class="locations">%s</td><td>%s</td></tr>' % (r[0],r[1])
       #print '<tr><td class="locations">',r,'</td></tr>'
       
    #print '<tr><th>first taxon</th><td class="locations">',rows[0],'</td></tr>'
    #print '<tr><th>last taxon</th><td class="locations">',rows[-1],'</td></tr>'

    print """<tr><td align="center" colspan="2"><hr><td></tr>"""
    print """<tr><td align="center">"""
    msg = config.get('info','updateactionlabel')
    print """<input type="submit" class="save" value="%s" name="action"></td>""" % msg
    print "<td></td>"
    print "\n</tr></table><hr/>"
    print """<input type="hidden" name="count" value="%s">""" % rowcount

def getHeader(updateType):

    if updateType == 'inventory':
    	return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Found</th>
      <th style="width:60px; text-align:center;">Not Found</th>
      <th>Notes</th>
    </tr>"""
    elif updateType == 'keyinfo':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Count</th>
      <th>Field Collection Place</th>
      <th>Cultural Group</th>
      <th>Ethnographic File Code</th>
      <th>P?</th>
    </tr>"""
    elif updateType == 'bedlist':
        return """
    <table><tr>
      <th>Object Number</th>
      <th>Data Quality</th>
      <th>Taxonomic Name</th>
      <th>Family</th>
    </tr>"""
     
    elif updateType == 'locreport':
        return """
    <table><tr>
      <th>Object Number</th>
      <th>Data Quality</th>
      <th>Taxonomic Name</th>
      <th>Family</th>
    </tr>"""
     
    elif updateType == 'keyinfoResult':
	return """
    <table width="100%" border="1">
    <tr>
      <th>Museum #</th>
      <th>CSID</th>
      <th>Status</th>
    </tr>"""
    elif updateType == 'inventoryResult':
        return """
    <table width="100%" border="1">
    <tr>
      <th>Museum #</th>
      <th>Updated Inventory Status</th>
      <th>Note</th>
      <th>Update status</th>
    </tr>"""
    elif updateType == 'barcodeprint':
        return """
    <table width="100%"><tr>
      <th>Location</th>
      <th>Objects found</th>
      <th>Barcode Filename</th>
      <th>Notes</th>
    </tr>"""

def doEnumerateObjects(form,config):

    updateactionlabel = config.get('info','updateactionlabel')
    updateType        = config.get('info','updatetype')
    if not validateParameters(form,config): return
        
    try:
        rows = cswaDB.getlocations(form.getvalue("lo.location1"),form.getvalue("lo.location2"),1,config,updateType)
    except:
        handleTimeout('enumerate',form)
        return

    print getHeader(updateType)

    if True:
        rowcount = len(rows)
        locations = {}
        for r in rows:
            locationheader = formatRow({ 'rowtype':'subheader','data': r },form,config)
            if locations.has_key(locationheader):
                pass
            else:
                locations[locationheader] = []
            
            locations[locationheader].append(formatRow({ 'rowtype': updateType,'data': r },form,config))

        locs = locations.keys()
        locs.sort()
        for header in locs:
            print header
            print '\n'.join(locations[header])

    print """<tr><td align="center" colspan="6"><hr><td></tr>"""
    print """<tr><td align="center" colspan="3">"""
    if rowcount != 0:
	if updateType == 'keyinfo':
	    msg = "Caution: clicking on the button at left will revise the above fields for <b>ALL %s objects</b> shown on this page!" % rowcount    
	else:
            msg = "Caution: clicking on the button at left will change the "+updateType+" of <b>ALL %s objects</b> shown on this page!" % rowcount
        print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="3">%s</td>''' % msg
    else:
        print '<span class="save">No objects found at this location.</span>'
        
    print "\n</table><hr/>"

def doUpdateKeyinfo(form,config):

    #print form
    CSIDs = []
    for i in form:
	if 'csid.' in i : 
	    CSIDs.append(form.getvalue(i))

    refNames2find = {}
    for row,csid in enumerate(CSIDs):

        index = csid # for now, the index is the csid
	if not refNames2find.has_key(form.getvalue('cp.'+index)):
            refNames2find[form.getvalue('cp.'+index)] = cswaDB.getrefname('places_common',form.getvalue('cp.'+index),config)
	if not refNames2find.has_key(form.getvalue('cg.'+index)):
            refNames2find[form.getvalue('cg.'+index)] = cswaDB.getrefname('concepts_common',form.getvalue('cg.'+index),config)
	if not refNames2find.has_key(form.getvalue('fc.'+index)):
            refNames2find[form.getvalue('fc.'+index)] = cswaDB.getrefname('concepts_common',form.getvalue('fc.'+index),config)

    print getHeader('keyinfoResult')

    #for r in refNames2find:
    #    print '<tr><td>%s<td>%s<td>%s</tr>' % ('refname',refNames2find[r],r)
    #print CSIDs

    numUpdated = 0
    for row,csid in enumerate(CSIDs):

	index = csid # for now, the index is the csid
        updateItems = {}
        updateItems['objectCsid']              = form.getvalue('csid.'+index)
        updateItems['objectName']              = form.getvalue('onm.'+index)
        updateItems['objectNumber']            = form.getvalue('oox.'+index)
        updateItems['objectCount']             = form.getvalue('ocn.'+index)
        updateItems['pahmaFieldCollectionPlace']  = refNames2find[form.getvalue('cp.'+index)]
        updateItems['assocPeople']                = refNames2find[form.getvalue('cg.'+index)]
        updateItems['pahmaEthnographicFileCode']  = refNames2find[form.getvalue('fc.'+index)]

        for i in ('handlerRefName',):
            updateItems[i] = form.getvalue(i)

        #print updateItems
        msg = 'updated.'
        try:
	    #pass
            updateKeyInfo(updateItems,config)
            numUpdated += 1
        except:
            msg = '<span style="color:red;">problem updating</span>'
        print ('<tr>'+ (3 * '<td class="ncell">%s</td>') +'</tr>\n') % (updateItems['objectNumber'],updateItems['objectCsid'],msg)
        #writeLog(updateItems,config)

    print "\n</table>"
    print '<h4>',numUpdated,'of',row+1,'object had key information updated</h4>'

def doUpdateLocations(form,config):

    updateValues = [ form.getvalue(i) for i in form if 'r.' in i ]
    
    print getHeader('inventoryResult')

    numUpdated = 0
    for row,object in enumerate(updateValues):

        updateItems = {}
        cells = object.split('|')
        updateItems['objectStatus']    = cells[0]
        updateItems['objectCsid']      = cells[1]
        updateItems['locationRefname'] = cells[2]
        updateItems['subjectCsid']     = '' # cells[3] is actually the csid of the movement record for the current location; the updated value gets inserted later
        updateItems['objectNumber']    = cells[4]
        updateItems['crate']           = cells[5]
        updateItems['reason']          = form.getvalue('reason')
        updateItems['inventoryNote']   = form.getvalue('n.'+cells[4]) if form.getvalue('n.'+cells[4]) else ''
        updateItems['locationDate']    = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
        updateItems['computedSummary'] = updateItems['locationDate'][0:10] + (' (%s)' % form.getvalue('reason')) 
        
        for i in ('handlerRefName',):
            updateItems[i] = form.getvalue(i)

        if updateItems['objectStatus'] == 'not found':
	    updateItems['locationRefname'] = "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl23524)'Not located'"
            updateItems['crate']           = ''

        #print updateItems
        msg = 'updated.'
        try:
            updateLocations(updateItems,config)
            numUpdated += 1
        except:
	    msg = '<span style="color:red;">problem updating</span>'
        print ('<tr>'+ (4 * '<td class="ncell">%s</td>') +'</tr>\n') % (updateItems['objectNumber'],updateItems['objectStatus'],updateItems['inventoryNote'],msg)
        writeLog(updateItems,config)

    print "\n</table>"
    print '<h4>',numUpdated,'of',row+1,'object locations updated</h4>'

def checkObject(places,objectInfo):
    if places == []:
	return True
    elif objectInfo[6] is None:
	return False
    elif objectInfo[6] in places:
	return True
    else:
	return False    

def doPackingList(form,config):

    updateactionlabel = config.get('info','updateactionlabel')
    updateType        = config.get('info','updatetype')
    updateType ='keyinfo'
    if not validateParameters(form,config): return

    place = form.getvalue("cp.place")
    if place != None:
        places = getPlaces.getPlaces(place)
    else:
	places = []

    if form.getvalue("lo.location2"):
	pass
        #form["location1"] = form.getvalue("lo.location2")
        #form["num2ret"] = 1
    
    num2ret = 30000

    try:
        locationList = cswaDB.getloclist('range',form.getvalue("lo.location1"),form.getvalue("lo.location2"),num2ret,config)
    except:
        raise
        handleTimeout(updateType,form)
        locationList = []

    rowcount = len(locationList)
    #print getHeader('keyinfo')

    if rowcount == 0:
	print '<tr><td width="500px"><h2>No locations in this range!</h2></td></tr>'
	return
    #else:
    #	showplace = place
    #   if showplace == '' : showplace = 'all places in this range'
    #   print '<tr><td width="500px"><h2>%s locations will be listed for %s.</h2></td></tr>' % (rowcount,showplace)

    print getHeader('keyinfo')
    totalobjects = 0
    for l in locationList:

        try:
            objects = cswaDB.getlocations(l[0],'',1,config,updateType)
        except:
            handleTimeout(updateType+' getting objects',form)
            return

        locationheader = formatRow({ 'rowtype':'subheader','data': l },form,config)
        locations = []
	if len(objects) == 0:
	    locations.append('</td><td colspan="3">No objects found at this location.</td>')
	else:
            for r in objects:
		#print "<tr><td>%s<td>%s</tr>" % (len(places),r[6])
		if checkObject(places,r):
		    totalobjects += 1
                    locations.append(formatRow({ 'rowtype': 'packinglist','data': r },form,config))

        print locationheader
        print '\n'.join(locations)
        print """<tr><td align="center" colspan="6">&nbsp;</tr>"""
    print """<tr><td align="center" colspan="6"><hr><td></tr>"""
    print """<tr><td align="center" colspan="6">Packing list completed. %s objects, %s locations</td></tr>""" % (totalobjects,len(locationList))
    print "\n</table><hr/>"

def doLocationList(form,config):

    updateactionlabel = config.get('info','updateactionlabel')
    updateType        = config.get('info','updatetype')
    updateType ='keyinfo'
    if not validateParameters(form,config): return

    Taxon = form.getvalue("cp.Taxon")
    if Taxon != None:
        Taxons = getTaxons.getTaxons(Taxon)
    else:
	Taxons = []

    if form.getvalue("lo.location2"):
	pass
        #form["location1"] = form.getvalue("lo.location2")
        #form["num2ret"] = 1
    
    num2ret = 30000

    try:
        locationList = cswaDB.getloclist('range',form.getvalue("lo.location1"),form.getvalue("lo.location2"),num2ret,config)
    except:
        raise
        handleTimeout(updateType,form)
        locationList = []

    rowcount = len(locationList)
    #print getHeader('keyinfo')

    if rowcount == 0:
	print '<tr><td width="500px"><h2>No locations in this range!</h2></td></tr>'
	return
    #else:
    #	showTaxon = Taxon
    #   if showTaxon == '' : showTaxon = 'all Taxons in this range'
    #   print '<tr><td width="500px"><h2>%s locations will be listed for %s.</h2></td></tr>' % (rowcount,showTaxon)

    print getHeader('keyinfo')
    totalobjects = 0
    for l in locationList:

        try:
            objects = cswaDB.getlocations(l[0],'',1,config,updateType)
        except:
            handleTimeout(updateType+' getting objects',form)
            return

        locationheader = formatRow({ 'rowtype':'subheader','data': l },form,config)
        locations = []
	if len(objects) == 0:
	    locations.append('</td><td colspan="3">No objects found at this location.</td>')
	else:
            for r in objects:
		#print "<tr><td>%s<td>%s</tr>" % (len(Taxons),r[6])
		if checkObject(Taxons,r):
		    totalobjects += 1
                    locations.append(formatRow({ 'rowtype': 'packinglist','data': r },form,config))

        print locationheader
        print '\n'.join(locations)
        print """<tr><td align="center" colspan="6">&nbsp;</tr>"""
    print """<tr><td align="center" colspan="6"><hr><td></tr>"""
    print """<tr><td align="center" colspan="6">Packing list completed. %s objects, %s locations</td></tr>""" % (totalobjects,len(locationList))
    print "\n</table><hr/>"


def downloadCsv(form,config):
    try:
        rows = cswaDB.getloclist('range',form.getvalue("lo.location1"),form.getvalue("lo.location2"),500,config)
    except:
        raise
        handleTimeout('downloadCSV',form)
        rows = []

    place = form.getvalue("cp.place")
    if place != None:
        places = getPlaces.getPlaces(place)
    else:
        places = []

    rowcount = len(rows)
    print 'Content-type: application/octet-stream; charset=utf-8'
    print 'Content-Disposition: attachment; filename="packinglist.xls"'
    print
    writer = csv.writer(sys.stdout,quoting=csv.QUOTE_ALL) 
    for r in rows:
        objects = cswaDB.getlocations(r[0],'',1,config,'keyinfo')
	for o in objects: 
	    if checkObject(places,o):
	        writer.writerow([o[x] for x in [0,2,3,4,5,6,7,9]])
    sys.stdout.flush()
    sys.stdout.close()

def doBarCodes(form,config):

    updateactionlabel = config.get('info','updateactionlabel')
    updateType        = config.get('info','updatetype')
    if not validateParameters(form,config): return

    print getHeader(updateType)

    try:
        rows = cswaDB.getloclist('range',form.getvalue("lo.location1"),form.getvalue("lo.location2"),500,config)
    except:
	raise
        handleTimeout(updateType,form)
	rows = []

    rowcount = len(rows)

    objectsHandled = []
    totalobjects = 0
    rows.reverse()
    for r in rows:
        objects = cswaDB.getlocations(r[0],'',1,config,updateType)
	for o in objects:
	    if o[3]+o[4] in objectsHandled:
	        objects.remove(o)
		print '<tr><td>already printed a label for</td><td>%s</td><td>%s</td><td/></tr>' % (o[3],o[4])
	    else:
	       objectsHandled.append(o[3]+o[4])
        totalobjects += len(objects)
        labelFilename = writeCommanderFile(r[0],form.getvalue("printer"),'objectLabels','objects',objects,config)
        print '<tr><td>%s</td><td>%s</td><tr><td colspan="4"><i>%s</i></td></tr>' % (r[0],len(objects),labelFilename)

    print """<tr><td align="center" colspan="4"><hr><td></tr>"""
    print """<tr><td align="center" colspan="4">"""
    if totalobjects != 0:    
        print "<b>%s objects</b> found in %s locations." % (totalobjects,rowcount)
    else:
        print '<span class="save">No objects found in this range.</span>'
        
    print "\n</td></tr></table><hr/>"

def doBedList(form,config):

    updateactionlabel = config.get('info','updateactionlabel')
    updateType        = config.get('info','updatetype')
    if not validateParameters(form,config): return

    if updateType == 'bedlist':
       try:
          rows = cswaDB.getloclist('range',form.getvalue("lo.location1"),form.getvalue("lo.location2"),500,config)
       except:
          raise
          handleTimeout(updateType,form)
          rows = []
    elif updateType == 'locreport':
       taxName = form.getvalue("ta.taxon")
       try:
          rows = getTaxname.getTaxon(taxName)
       except:
          raise
          handleTimeout('countTaxa',form)
          rows = []
    
    rowcount = len(rows)
    print getHeader(updateType)
    totalobjects = 0
    for l in rows:

        try:
            objects = cswaDB.getplants(l[0],'',1,config,updateType)
        except:
            raise
            handleTimeout('getplants',form)
            objects = []

        print formatRow({ 'rowtype':'subheader','data': l },form,config)
        #print "<tr><td>",l,"</td></tr>"
        if len(objects) == 0:
            print '<tr><td colspan="6">No objects found at this location.</td></tr>'
        else:
            for r in objects:
                #print "<tr><td>%s<td>%s</tr>" % (len(places),r[6])
                #if checkObject(places,r):
                if True:
                    totalobjects += 1
                    print formatRow({ 'rowtype': updateType,'data': r },form,config)

        print """<tr><td align="center" colspan="6">&nbsp;</tr>"""
    print """<tr><td align="center" colspan="6"><hr><td></tr>"""
    print """<tr><td align="center" colspan="6">Bed List completed. %s objects, %s locations</td></tr>""" % (totalobjects,len(rows))
    print "\n</table><hr/>"

def writeCommanderFile(location,printerDir,dataType,filenameinfo,data,config):
 
    auditFile = config.get('files','cmdrauditfile')
    # slugify the location
    slug = re.sub('[^\w-]+', '_', location).strip().lower()
    logFile = config.get('files','cmdrfmtstring') % (config.get('files','cmdrfileprefix'),dataType,printerDir,slug,datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S"),filenameinfo)
    #logFile = '/tmp/%s.%s.%s.txt' % (re.sub(r'\W+','_',location),datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S"),filenameinfo)

    try:
	logFh    = codecs.open(logFile,'w','utf-8')
        csvlogfh = csv.writer(logFh, delimiter=",",quoting=csv.QUOTE_ALL)
        audlogfh = csv.writer(codecs.open(auditFile,'a','utf-8'), delimiter=",",quoting=csv.QUOTE_ALL)
	csvlogfh.writerow('MuseumNumber,ObjectName,PieceCount,FieldCollectionPlace,AssociatedCulture,EthnographicFileCode'.split(','))
	for d in data:
	    csvlogfh.writerow(d[3:8])
	    audlogfh.writerow(d)
	logFh.close()
        newName = logFile.replace('.tmp','.txt')
        os.rename (logFile,newName) 
    except:
	newName = '<span style="color:red;">could not write to %s</span>' % logFile

    return newName

def writeLog(updateItems,config):
 
    auditFile = config.get('files','auditfile')
    myPid = str(os.getpid())
    # writing of individual log files is now disabled. audit file contains the same data.
    #logFile = config.get('files','logfileprefix') + '.' + datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S") + myPid + '.csv'

    # yes, it is inefficient open the log to write each row, but in the big picture, it's insignificant
    try:
        #csvlogfh = csv.writer(codecs.open(logFile,'a','utf-8'), delimiter="\t")
	#csvlogfh.writerow([updateItems['locationDate'],updateItems['objectNumber'],updateItems['objectStatus'],updateItems['subjectCsid'],updateItems['objectCsid'],updateItems['handlerRefName']])
        csvlogfh = csv.writer(codecs.open(auditFile,'a','utf-8'), delimiter="\t")
	csvlogfh.writerow([updateItems['locationDate'],updateItems['objectNumber'],updateItems['objectStatus'],updateItems['subjectCsid'],updateItems['objectCsid'],updateItems['handlerRefName']])
    except:
	print 'log failed!'
	pass

def writeInfo2log(request,form,config,elapsedtime):

    location1 = str(form.getvalue("lo.location1"))
    location2 = str(form.getvalue("lo.location2"))
    action = str(form.getvalue("action"))
    serverlabel = config.get('info','serverlabel')
    apptitle = config.get('info','apptitle')
    updateType = config.get('info','updatetype')
    sys.stderr.write('%-13s:: %-18s:: %-6s::%8.2f :: %-15s :: %s :: %s\n' % (updateType,action,request,elapsedtime,serverlabel,location1,location2))
  
def uploadFile(form,config):

    barcodedir = config.get('files','barcodedir')
    barcodeprefix = config.get('files','barcodeprefix')
    #print form
    # we are using <form enctype="multipart/form-data"...>, so the file contents are now in the FieldStorage.
    # we just need to save it somewhere...
    fileitem = form['file']

    # Test if the file was uploaded
    if fileitem.filename:
   
        # strip leading path from file name to avoid directory traversal attacks
        fn = os.path.basename(fileitem.filename)
        open(barcodedir + '/' + barcodeprefix + '.' + fn, 'wb').write(fileitem.file.read())
	os.chmod(barcodedir + '/' + barcodeprefix + '.' + fn,0666)
        message = fn + ' was uploaded successfully'
    else:
        message = 'No file was uploaded'

    print "<h3>%s</h3>" % message
 
def viewLog(form,config):
    num2ret   = int(form.getvalue('num2ret')) if str(form.getvalue('num2ret')).isdigit() else 100
    
    print '<table width="100%">\n'
    print ('<tr>'+ (4 * '<th class="ncell">%s</td>') +'</tr>\n') % ('locationDate','objectNumber','objectStatus','handler')
    try:
        auditFile = config.get('files','auditfile')
        file_handle = open(auditFile)
        file_size = file_handle.tell()
        file_handle.seek(max(file_size - 9*1024, 0))

        lastn = file_handle.read().splitlines()[-num2ret:]
        for i in lastn:
 	    i = i.replace('urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name','')
            line = ''
            if i[0] == '#' : continue
	    for l in [i.split('\t')[x] for x in [0,1,2,5]] : line += ('<td>%s</td>' % l)
	    #for l in i.split('\t') : line += ('<td>%s</td>' % l)
            print '<tr>' + line  + '</tr>'

    except:
	print '<tr><td colspan="4">failed. sorry.</td></tr>'

    print '</table>'

def alreadyExists(txt,elements):
    for e in elements:
        if txt in str(e.text):
            #print "    found,skipping: ",txt
            return True
    return False

def updateKeyInfo(updateItems,config):

    realm    = config.get('connect','realm')
    hostname = config.get('connect','hostname')
    username = config.get('connect','username')
    password = config.get('connect','password')

    uri = 'collectionobjects'
    getItems = updateItems['objectCsid']

    # get the XML for this object
    url,content,elapsedtime = getxml(uri,realm,hostname,username,password,getItems)
    root = etree.fromstring(content)
    # add the user's changes to the XML
    for relationType in ('pahmaFieldCollectionPlace','assocPeople','objectName','pahmaEthnographicFileCode'):
	# skip if no refName was provided to update
        if updateItems[relationType] == '':
	    continue
        if relationType == 'assocPeople':
	    extra = 'Group'
	else:
	    extra = ''
	#print ">>> ",'.//'+relationType+extra+'List'
        metadata = root.find('.//'+relationType+extra+'List')
	# check if value is already present. if so, skip
	#print(etree.tostring(metadata, pretty_print=True))
	#print ">>> ",relationType,':',updateItems[relationType]
        if alreadyExists(updateItems[relationType],metadata): continue
        if relationType in ['assocPeople','objectName']:
            #group = metadata.findall('.//'+relationType+'Group')
	    if not alreadyExists(updateItems[relationType],metadata.findall('.//'+relationType)):
                newElement = etree.Element(relationType+'Group')
                leafElement = etree.Element(relationType)
                leafElement.text = updateItems[relationType]
                newElement.append(leafElement)
	        if relationType == 'assocPeople':
                    apgNote = etree.Element('assocPeopleNote')
                    apgNote.text = 'made by'
                    newElement.append(apgNote)
                metadata.insert(0,newElement)
        else:
	    newElement = etree.Element(relationType)
            newElement.text = updateItems[relationType]
            metadata.insert(0,newElement)
        #print(etree.tostring(metadata, pretty_print=True))
    objectCount = root.find('.//numberOfObjects')
    objectCount.text = updateItems['objectCount']
    #print(etree.tostring(root, pretty_print=True))
 
    uri     = 'collectionobjects' + '/' + updateItems['objectCsid']
    payload = '<?xml version="1.0" encoding="UTF-8"?>\n' + etree.tostring(root)
    # update collectionobject..
    #print "<br>pretending to post update to %s to REST API..." % updateItems['objectCsid']
    (url,data,csid,elapsedtime) = postxml('PUT',uri,realm,hostname,username,password,payload)

    #print "<h3>Done w update!</h3>"

def updateLocations(updateItems,config):
 
    realm    = config.get('connect','realm')
    hostname = config.get('connect','hostname')
    username = config.get('connect','username')
    password = config.get('connect','password')
    
    uri     = 'movements'
    
    #print "<br>posting to movements REST API..."
    payload = lmiPayload(updateItems)
    (url,data,csid,elapsedtime) =  postxml('POST',uri,realm,hostname,username,password,payload)
    updateItems['subjectCsid'] = csid

    uri     = 'relations'

    #print "<br>posting inv2obj to relations REST API..."
    updateItems['subjectDocumentType'] = 'Movement'
    updateItems['objectDocumentType']  = 'CollectionObject'
    payload = relationsPayload(updateItems)
    (url,data,csid,elapsedtime) =  postxml('POST',uri,realm,hostname,username,password,payload)

    # reverse the roles
    #print "<br>posting obj2inv to relations REST API..."
    temp                               = updateItems['objectCsid']
    updateItems['objectCsid']          = updateItems['subjectCsid']
    updateItems['subjectCsid']         = temp
    updateItems['subjectDocumentType'] = 'CollectionObject'
    updateItems['objectDocumentType']  = 'Movement'
    payload = relationsPayload(updateItems)
    (url,data,csid,elapsedtime) = postxml('POST',uri,realm,hostname,username,password,payload)

    #print "<h3>Done w update!</h3>"
    
def formatRow(result,form,config):
    hostname = config.get('connect','hostname')
    if result['rowtype'] == 'subheader':
        #return """<tr><td colspan="4" class="subheader">%s</td><td>%s</td></tr>""" % result['data'][0:1]
        return """<tr><td colspan="7" class="subheader">%s</td></tr>""" % result['data'][0]
    elif result['rowtype'] == 'location':
        handler = form.getvalue('handlerRefName')
        return '''<tr><td class="objno"><a href="#" onclick="formSubmit('%s')">%s</a></td><td/></tr>''' % (result['data'][0],result['data'][0])
    elif result['rowtype'] == 'bedlist':
        rr = result['data']
	link = 'http://'+hostname+':8180/collectionspace/ui/botgarden/html/cataloging.html?csid=%s' % rr[7] 
        # 3 recordstatus | 4 Accession number | 5 Determination | 6 Family | 7 object csid
        #### 3 Accession number | 4 Data quality | 5 Taxonomic name | 6 Family | 7 object csid
        return '''<tr><td class="objno"><a target="cspace" href="%s">%s</a</td><td>%s</td><td>%s</td><td>%s</td></tr>''' % (link,rr[4],rr[3],rr[5],rr[6])
    elif result['rowtype'] == 'locreport':
        rr = result['data']
	link = 'http://'+hostname+':8180/collectionspace/ui/botgarden/html/cataloging.html?csid=%s' % rr[7] 
        # 3 recordstatus | 4 Accession number | 5 Determination | 6 Family | 7 object csid
        #### 3 Accession number | 4 Data quality | 5 Taxonomic name | 6 Family | 7 object csid
        return '''<tr><td class="objno"><a target="cspace" href="%s">%s</a</td><td>%s</td><td>%s</td><td>%s</td></tr>''' % (link,rr[4],rr[3],rr[5],rr[6])
    elif result['rowtype'] == 'inventory':
        rr = result['data']
	rr = [ x if x != None else '' for x in rr]
	link = 'http://'+hostname+':8180/collectionspace/ui/pahma/html/cataloging.html?csid=%s' % rr[8] 
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objcount 4 | objname 5| movecsid 6 | locrefname 7 | objcsid 8 | objrefname 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td class="rdo" ><input type="radio" name="r.%s" value="found|%s|%s|%s|%s|%s" checked></td><td class="rdo" ><input type="radio" name="r.%s" value="not found|%s|%s|%s|%s|%s"></td><td><input class="xspan" type="text" size="65" name="n.%s"></td></tr>""" % (link,rr[3],rr[5],rr[3], rr[8],rr[7],rr[6],rr[3],rr[14], rr[3], rr[8],rr[7],rr[6],rr[3],rr[14], rr[3])    
    elif result['rowtype'] == 'keyinfo':
        rr = result['data']
	rr = [ x if x != None else '' for x in rr]
	link = 'http://'+hostname+':8180/collectionspace/ui/pahma/html/cataloging.html?csid=%s' % rr[8] 
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objname 4 | objcount 5| fieldcollectionplace 6 | culturalgroup 7 | objcsid 8 | ethnographicfilecode 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname">
<input class="objname" type="text" name="onm.%s" value="%s">
</td>
<td class="veryshortinput">
<input class="veryshortinput" type="text" name="ocn.%s" value="%s">
</td>
<td>
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<input class="xspan" type="text" size="26" name="cp.%s" value="%s"></td>
<td><input class="xspan" type="text" size="26" name="cg.%s" value="%s"></td>
<td><input class="xspan" type="text" size="26" name="fc.%s" value="%s"></td>
</tr>""" % (link,rr[3], rr[8],rr[4], rr[8],rr[5], rr[8],rr[3], rr[8],rr[8], rr[8],rr[6], rr[8],rr[7], rr[8],rr[9])

    elif result['rowtype'] == 'packinglist':
        rr = result['data']
        rr = [ x if x != None else '' for x in rr]
        link = 'http://'+hostname+':8180/collectionspace/ui/pahma/html/cataloging.html?csid=%s' % rr[8]
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objname 4 | objcount 5| fieldcollectionplace 6 | culturalgroup 7 | objcsid 8 | ethnographicfilecode 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname" name="onm.%s">%s</td>
<td class="xspan" name="ocn.%s">%s</td>
<td class="xspan" name="cp.%s">%s</td>
<td class="xspan" name="cg.%s">%s</td>
<td class="xspan" name="fc.%s">%s</td>
<td><input type="checkbox"></td>
</tr>""" % (link,rr[3], rr[8],rr[4], rr[8],rr[5],  rr[8],rr[6], rr[8],rr[7], rr[8],rr[9])


def formatError(cspaceObject):
    return '<tr><th colspan="2" class="leftjust">%s</th><td></td><td>None found.</td></tr>\n' % (cspaceObject)

def getxml(uri,realm,hostname,username,password,getItems):
    
    server = "http://" + hostname + ":8180"
    passman = urllib2.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passman)
    opener = urllib2.build_opener(authhandler)
    urllib2.install_opener(opener)
    if getItems == None: getItems = ''
    url = "%s/cspace-services/%s/%s" % (server,uri,getItems)
    elapsedtime = 0

    try:
        elapsedtime = time.time()
        f = urllib2.urlopen(url)
        data = f.read()
        elapsedtime = time.time() - elapsedtime
    except urllib2.HTTPError, e:
        print 'The server couldn\'t fulfill the request.'
        print 'Error code: ', e.code
        raise
    except urllib2.URLError, e:
        print 'We failed to reach a server.'
        print 'Reason: ', e.reason
        raise
    else:
        return (url,data,elapsedtime)
    
    #data = "\n<h3>%s :: %s</h3>" % e


def postxml(requestType,uri,realm,hostname,username,password,payload):
    
    server = "http://" + hostname + ":8180"
    passman = urllib2.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passman)
    opener = urllib2.build_opener(authhandler)
    urllib2.install_opener(opener)
    url = "%s/cspace-services/%s" % (server,uri)
    elapsedtime = 0.0

    elapsedtime = time.time()
    request = urllib2.Request(url, payload, { 'Content-Type': 'application/xml' })
    # default method for urllib2 with payload is POST
    if requestType == 'PUT': request.get_method = lambda: 'PUT'
    try:
        f = urllib2.urlopen(request)
    except urllib2.URLError, e:
        if hasattr(e, 'reason'):
            sys.stderr.write('We failed to reach a server.\n')
            sys.stderr.write('Reason: '+str(e.reason)+'\n')
        elif hasattr(e, 'code'):
            sys.stderr.write('The server couldn\'t fulfill the request.\n')
            sys.stderr.write('Error code: '+str(e.code)+'\n')
        elif True:
            #print 'Error in POSTing!'
            print request
            raise
            sys.stderr.write("Error in POSTing!\n")
            sys.stderr.write(url)
    #sys.stderr.write(payload)
    #print url
    #print payload
    #raise
    data = f.read()     
    info = f.info()
    # if a POST, the Location element contains the new CSID
    if info.getheader('Location'):
        csid = re.search(uri+'/(.*)',info.getheader('Location'))
        csid = csid.group(1)
    else:
        csid = ''
    elapsedtime = time.time() - elapsedtime
    return (url,data,csid,elapsedtime)

def getHandlers(form):

    selected = form.getvalue('handlerRefName')
    handlerlist = [ \
("Thusa Chu", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7654)'Thusa Chu'"),
("Madeleine Fang", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7248)'Madeleine W. Fang'"),
("Alicja Egbert", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8683)'Alicja Egbert'"),
("Leslie Freund", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7475)'Leslie Freund'"),
("Rowan Gard", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(RowanGard1342219780674)'Rowan Gard'"),
("Ryan Gross", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8737)'Ryan Gross'"),
("Natasha Johnson", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7652)'Natasha Johnson'"),
("Allison Lewis", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8724)'Allison Lewis'"),
("Corri MacEwen", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(9090)'Corri MacEwen'"),
("Martina Smith", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(9034)'Martina Smith'"),
("Jane Williams", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7420)'Jane L. Williams'")
]

    handlers = '''
          <select class="cell" name="handlerRefName">
              <option value="None">Select a handler</option>'''
              
    for handler in handlerlist:
        #print handler
        handlerOption = """<option value="%s">%s</option>""" % (handler[1],handler[0])
        #print "xxxx",selected
        if selected and str(selected) in handler[1]:
            handlerOption = handlerOption.replace('option','option selected')
        handlers = handlers + handlerOption

    handlers = handlers + '\n      </select>'
    return handlers,selected
    
def getReasons(form):

    reason = form.getvalue('reason')

    reasons =  '''
<select class="cell" name="reason">
<option value="None">(none selected)</option>
<option value="(not entered)">(not entered)</option>
<option value="Inventory">Inventory</option>
<option value="GeneralCollManagement">General Collections Management</option>
<option value="Research">Research</option>
<option value="NAGPRA">NAGPRA</option>
<option value="pershelflabel">per shelf label</option>
<option value="NewHomeLocation">New Home Location</option>
<option value="Loan">Loan</option>
<option value="Exhibit">Exhibit</option>
<option value="ClassUse">Class Use</option>
<option value="PhotoRequest">Photo Request</option>
<option value="Tour">Tour</option>
<option value="Conservation">Conservation</option>
<option value="CulturalHeritage">cultural heritage</option>
<option value="">----------------------------</option>
<option value="2012 HGB surge pre-move inventory">2012 HGB surge pre-move inventory</option>
<option value="AsianTextileGrant">Asian Textile Grant</option>
<option value="BasketryRehousingProj">Basketry Rehousing Proj</option>
<option value="BORProj">BOR Proj</option>
<option value="BuildingMaintenance">Building Maintenance: Seismic</option>
<option value="CaliforniaArchaeologyProj">California Archaeology Proj</option>
<option value="CatNumIssueInvestigation">Cat. No. Issue Investigation</option>
<option value="DuctCleaningProj">Duct Cleaning Proj</option>
<option value="FederalCurationAct">Federal Curation Act</option>
<option value="FireAlarmProj">Fire Alarm Proj</option>
<option value="FirstTimeStorage">First Time Storage</option>
<option value="FoundinColl">Found in Collections</option>
<option value="HearstGymBasementMoveKroeber20">Hearst Gym Basement move to Kroeber 20A</option>
<option value="HGB Surge">HGB Surge</option>
<option value="Kro20MezzLWeaponProj2011">Kro20Mezz LWeapon Proj 2011</option>
<option value="Kroeber20AMoveRegatta">Kroeber 20A move to Regatta</option>
<option value="MarchantFlood2007">Marchant Flood 12/2007</option>
<option value="NAAGVisit">Native Am Adv Grp Visit</option>
<option value="NEHEgyptianCollectionGrant">NEH Egyptian Collection Grant</option>
<option value="Regattamovein">Regatta move-in</option>
<option value="Regattapremoveinventory">Regatta pre-move inventory</option>
<option value="Regattapremoveobjectprep">Regatta pre-move object prep.</option>
<option value="Regattapremovestaging">Regatta pre-move staging</option>
<option value="SATgrant">SAT grant</option>
<option value="TemporaryStorage">Temporary Storage</option>
<option value="TextileRehousingProj">Textile Rehousing Proj</option>
<option value="YorubaMLNGrant">Yoruba MLN Grant</option>
</select>
'''
    reasons = reasons.replace(('option value="%s"' % reason),('option selected value="%s"' % reason))
    return reasons,reason

def getPrinters(form):

    selected = form.getvalue('printer')

    printerlist = [ \
        ("Kroeber Hall", "kroeberBCP"),
        ("Hearst Gym Basement", "hearstBCP"),
        ("Regatta Building", "regattaBCP")
        ]

    printers = '''
          <select class="cell" name="printer">
              <option value="None">Select a printer</option>'''
              
    for printer in printerlist:
        printerOption = """<option value="%s">%s</option>""" % (printer[1],printer[0])
        if selected and str(selected) in printer[1]:
            printerOption = printerOption.replace('option','option selected')
        printers = printers + printerOption

    printers = printers + '\n      </select>'
    return printers,selected

def selectWebapp():

    return '''Content-type: text/html; charset=utf-8

    
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Select web app</title>
<h1>Oops!</h1>
<h3>you need to pick a webapp<h3>
</html>'''

def starthtml(form,config):
   
    if config == False:
	print selectWebapp()
        sys.exit(0)
 
    writeInfo2log('start',form,config,0.0) 
    logo = config.get('info','logo')
    schemacolor1 = config.get('info','schemacolor1')
    serverlabel = config.get('info','serverlabel')
    serverlabelcolor = config.get('info','serverlabelcolor')
    apptitle = config.get('info','apptitle')
    updateType = config.get('info','updatetype')

    location1 = str(form.getvalue("lo.location1")) if form.getvalue("lo.location1") else ''
    location2 = str(form.getvalue("lo.location2")) if form.getvalue("lo.location2") else ''
    num2ret   = str(form.getvalue('num2ret')) if str(form.getvalue('num2ret')).isdigit() else '50'

    button = '''
          <input id="actionbutton" class="save" type="submit" value="Search" name="action">
          <br/><input id="actionbuttonprev" class="save" type="submit" value="<<" name="previous">
          <input id="actionbuttonnext" class="save" type="submit" value=">>" name="next">
    '''

    otherfields = '''
	  <tr><td><span class="cell">start:</span></td>
	  <td><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></td>
          <td><span class="cell">end:</span></td>
          <td><input id="lo.location2" class="cell" type="text" size="40" name="lo.location2" value="''' + location2 + '''" class="xspan"></td></tr>
    '''

    if updateType == 'keyinfo':
	otherfields += '''
	  <tr><td/><td/><td/><td/></tr>'''
    elif updateType == 'locreport':
        taxName        = str(form.getvalue('ta.taxon')) if form.getvalue('ta.taxon') else ''
	otherfields = '''
	  <tr><td><span class="cell">taxonomic name:</span></td>
	  <td><input id="ob.objectnumber" class="cell" type="text" size="40" name="ta.taxon" value="''' + taxName + '''" class="xspan"></td></tr>'''
    elif updateType == 'search':
        objectnumber = str(form.getvalue('ob.objectnumber')) if form.getvalue('ob.objectnumber') else ''
        place        = str(form.getvalue('cp.place')) if form.getvalue('cp.place') else ''
        concept      = str(form.getvalue('co.concept')) if form.getvalue('co.concept') else ''
	otherfields += '''
	  <tr><td><span class="cell">museum number:</span></td>
	  <td><input id="ob.objectnumber" class="cell" type="text" size="40" name="ob.objectnumber" value="''' + objectnumber + '''" class="xspan"></td></tr>
	  <tr><td><span class="cell">concept:</span></td>
	  <td><input id="co.concept" class="cell" type="text" size="40" name="co.concept" value="''' + concept + '''" class="xspan"></td></tr>
	  <tr><td><span class="cell">place:</span></td>
	  <td><input id="cp.place" class="cell" type="text" size="40" name="cp.place" value="''' + place + '''" class="xspan"></td></tr>'''
    elif updateType == 'barcodeprint':
        printers,selected = getPrinters(form)
	otherfields += '''
          <tr><td><span class="cell">printer:</span></td><td>''' + printers + '''</td></tr>'''
    elif updateType == 'inventory':
        handlers,selected = getHandlers(form)
        reasons,selected  = getReasons(form)
	otherfields += '''
          <tr><td><span class="cell">reason:</span></td><td>''' + reasons + '''</td>
          <td><span class="cell">handler:</span></td><td>''' + handlers + '''</td></tr>'''
    elif updateType == 'packinglist':
        place = str(form.getvalue('cp.place')) if form.getvalue('cp.place') else ''
	otherfields +='''
	  <tr><td><span class="cell">place:</span></td>
	  <td><input id="cp.place" class="cell" type="text" size="40" name="cp.place" value="''' + place + '''" class="xspan"></td></tr>'''
    elif updateType == 'upload':
        button = '''<input id="actionbutton" class="save" type="submit" value="Upload" name="action">'''
	otherfields = '''<tr><td><span class="cell">file:</span></td><td><input type="file" name="file"></td><td/></tr>'''
    elif False:
        otherfields += '''
          <td><span class="cell">number to retrieve:</span></td>
          <td><input id="num2ret" class="cell" type="text" size="4" name="num2ret" value="''' + num2ret + '''" class="xspan"></td></tr>
          <tr><td/><td/><td/><td/></tr>'''

    return '''Content-type: text/html; charset=utf-8

    
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>''' + apptitle + ' : ' + serverlabel + '''</title>
<style type="text/css">
body { margin:10px 10px 0px 10px; font-family: Arial, Helvetica, sans-serif; }
table { width: 100%; }
td { cell-padding: 3px; }
th { text-align: left ;color: #666666; font-size: 16px; font-weight: bold; cell-padding: 3px;}
h1 { font-size:32px; float:left; padding:10px; margin:0px; border-bottom: none; }
h2 { font-size:12px; float:left; color:white; background:black; }
p { padding:10px 10px 10px 10px; }

button { font-size: 150%; width:85px; text-align: center; text-transform: uppercase;}

.cell { line-height: 1.0; text-indent: 2px; color: #666666; font-size: 16px;}
.enumerate { background-color: green; font-size:20px; color: #FFFFFF; font-weight:bold; vertical-align: middle; text-align: center; }
img#logo { float:left; height:50px; padding:10px 10px 10px 10px;}
.locations { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 18px; }
.ncell { line-height: 1.0; cell-padding: 2px; font-size: 16px;}
.objname { font-weight: bold; font-size: 16px; font-style: italic; width:200px; }
.objno { font-weight: bold; font-size: 16px; font-style: italic; width:110px; }
.objno { font-weight: bold; font-size: 16px; font-style: italic; width:160px; }
.ui-tabs .ui-tabs-panel { padding: 0px; min-height:120px; }
.rdo { text-align: center; }
.save { background-color: orange; font-size:20px; color: #000000; font-weight:bold; vertical-align: middle; text-align: center; }
.shortinput { font-weight: bold; width:150px; }
.subheader { background-color: ''' + schemacolor1 + '''; color: #FFFFFF; font-size: 24px; font-weight: bold; }
.veryshortinput { width:60px; }
.xspan { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 12px; }
</style>
<style type="text/css">
  /*<![CDATA[*/
    @import "../css/autoSuggest.css";
    @import "../css/jquery-ui-1.8.22.custom.css";
  /*]]>*/
  </style>
<script type="text/javascript" src="../js/jquery-1.7.2.min.js"></script>
<script type="text/javascript" src="../js/jquery-ui-1.8.22.custom.min.js"></script>
<script type="text/javascript" src="../js/provision.js"></script>
<script type="text/javascript" src="../js/jquery.autoSuggest.js"></script>
<style>
.ui-autocomplete-loading { background: white url('../images/ui-anim_basic_16x16.gif') right center no-repeat; }
</style>
<script type="text/javascript">
function formSubmit(location)
{
    console.log(location);
    document.getElementById('lo.location1').value = location
    document.getElementById('lo.location2').value = location
    //document.getElementById('num2ret').value = 1
    //document.getElementById('actionbutton').value = "Next"
    document.forms['sysinv'].submit();
}
</script>
</head>
<body>
<form id="sysinv" enctype="multipart/form-data" method="post">
<table width="100%" cellpadding="0" cellspacing="0" border="0">
  <tbody><tr><td width="3%">&nbsp;</td><td align="center">
  <div id="sidiv" style="position:relative;width:1000px;height:750px;">
    <table width="100%">
    <tbody>
      <tr>
	<td style="width: 400px; color: #000000; font-size: 32px; font-weight: bold;">''' + apptitle + '''</td>
        <td><span style="color:''' + serverlabelcolor + ''';">''' + serverlabel + '''</td>
	<th style="text-align:right;"><img height="60px" src="''' + logo + '''"></th>
      </tr>
      <tr><td colspan="3"><hr/></td></tr>
      <tr>
	<td colspan="3">
	<table>
	  <tr><td><table>
	  ''' + otherfields + '''
	</table>
        </td><td style="width:3%"/>
	<td style="width:120px;text-align:center;">''' + button + '''</td>
      </tr>
      </table></td></tr>
      <tr><td colspan="3"><div id="status"><hr/></div></td></tr>
    </tbody>
    </table>
'''

def endhtml(form,config,elapsedtime):
    writeInfo2log('end',form,config,elapsedtime) 
    #user = form.getvalue('user')
    count = form.getvalue('count')
    connect_string = config.get('connect','connect_string')
    return '''
  <table width="100%">
    <tbody>
    <tr>
      <td width="180px" class="xspan">''' + time.strftime("%b %d %Y %H:%M:%S", time.localtime()) + '''</td>
      <td width="160px" class="cell">elapsed time: </td>
      <td class="xspan">''' + ('%8.2f' % elapsedtime) + ''' seconds</td>
      <td width="200px" class="cell"><input type="submit" value="Recent Activity" name="action"></td>
    </tr>
    </tbody>
  </table>
</div>
</td><td width="3%">&nbsp;</td></tr>
</tbody></table>
</form>
<script>
$(document).ready(function () {
$('[name]').map(function() {
    var elementID = $(this).attr('name');
    if (elementID.indexOf('.') == 2) {
        console.log(elementID);
        $(this).autocomplete({
            source: function(request, response) {
                $.ajax({
                    url: "../cgi-bin/autosuggest2.py?connect_string=''' + connect_string + '''",
                    dataType: "json",
                    data: {
                        q : request.term,
                        elementID : elementID
                    },
                    success: function(data) {
                        response(data);
                    }
                });
            },
            minLength: 2,
        });
    }
});
});
</script>
</body></html>
'''

def relationsPayload(f):
    payload = """<?xml version="1.0" encoding="UTF-8"?>
<document name="relations">
  <ns2:relations_common xmlns:ns2="http://collectionspace.org/services/relation" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <relationshipType>affects</relationshipType>
    <objectCsid>%s</objectCsid>
    <objectDocumentType>%s</objectDocumentType>
    <subjectCsid>%s</subjectCsid>
    <subjectDocumentType>%s</subjectDocumentType>
  </ns2:relations_common>
</document>
"""
    payload = payload % (f['objectCsid'],f['objectDocumentType'],f['subjectCsid'],f['subjectDocumentType'])
    return payload

def lmiPayload(f):

    payload = """<?xml version="1.0" encoding="UTF-8"?>
<document name="movements">
<ns2:movements_common xmlns:ns2="http://collectionspace.org/services/movement" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<reasonForMove>%s</reasonForMove>
<currentLocation>%s</currentLocation>
<currentLocationFitness>suitable</currentLocationFitness>
<locationDate>%s</locationDate>
<movementNote>%s</movementNote>
</ns2:movements_common>
<ns2:movements_anthropology xmlns:ns2="http://collectionspace.org/services/movement/domain/anthropology" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<computedSummary>%s</computedSummary>
<crate>%s</crate>
<locationHandlers>
<locationHandler>%s</locationHandler>
</locationHandlers>
</ns2:movements_anthropology>
</document>
"""
    payload = payload % (f['reason'],f['locationRefname'],f['locationDate'],f['inventoryNote'],f['computedSummary'],f['crate'],f['handlerRefName'])
    return payload


if __name__ == "__main__":


    # to test this module on the command line you have to pass in two cgi values:
    # $ python cswaUtils.py "lo.location1=Hearst Gym, 30, L 12,  2&lo.location2=Hearst Gym, 30, L 12,  7"
    # $ python cswaUtils.py "lo.location1=X&lo.location2=Y"

    # this will load the config file and attempt to update some records in server identified
    # in that config file!
    import cswaDB
    
    form = cgi.FieldStorage()
    config = getConfig(form)

    config = getConfig('ucbgLocationReport.cfg')
    print cswaDB.getplants('Velleia rosea','',1,config,'locreport')
    sys.exit()
    
    realm    = config.get('connect','realm')
    hostname = config.get('connect','hostname')
    username = config.get('connect','username')
    password = config.get('connect','password')

    starthtml(form,config)
    endhtml(form,config,0.0)

    #print "starting packing list"
    #doPackingList(form,config)
    #sys.exit()
    print '\nlocations\n'
    for loc in cswaDB.getloclist('range','1001, Green House 1','1003, Tropical House',1000,config):
        print loc
    sys.exit()


    print '\nlocations\n'
    for loc in cswaDB.getloclist('set','Kroeber, 20A, W B','',10,config):
        print loc

    print '\nlocations\n'
    for loc in cswaDB.getloclist('set','Kroeber, 20A, CC  4','',3,config):
        print loc

    print '\nobjects\n'
    rows = cswaDB.getlocations('Kroeber, 20A, CC  4','',3,config,'keyinfo')
    for r in rows:
	print r

    #urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl31520)'Regatta, A150, RiveTier 1, B'
    f = { 'objectCsid'      : '242e9ee7-983a-49e9-b3b5-7b49dd403aa2',
          'subjectCsid'     : '250d75dc-c704-4b3b-abaa',
          'locationRefname' : "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl284)'Kroeber, 20Mez, 53 D'",
          'locationDate' : '2000-01-01T00:00:00Z',
          'computedSummary' : 'systematic inventory test',
          'inventoryNote' : 'this is a test inventory note',
          'objectDocumentType'  : 'CollectionObject',
          'subjectDocumentType' : 'Movement',
          'reason'          : 'Inventory',
          'handlerRefName'  : "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7412)'Madeleine W. Fang'"
         
          }
        
    #print lmiPayload(f)
    #print relationsPayload(f)

    f2 = {'objectStatus': 'found', 'subjectCsid': '', 'inventoryNote': '', 'crate': "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(crate):item:name(cr2113)'Faunal Box 421'", 'handlerRefName': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(999)'Michael T. Black'", 'objectCsid': '35d1e048-e803-4e19-81de-ac1079f9bf47', 'reason': 'Inventory', 'computedSummary': 'systematic inventory test', 'locationRefname': "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl12158)'Kroeber, 20A, AA 1, 2'", 'locationDate': '2012-07-24T05:45:30Z', 'objectNumber': '9-12689'} 

    updateLocations(f2,config)
    print "updateLocations succeeded..."
    sys.exit(0)

    uri     = 'movements'
    
    payload = lmiPayload(f)
    print "posting to movements REST API..."
    (url,data,csid,elapsedtime) =  postxml('POST',uri,realm,hostname,username,password,payload)
    print 'got csid',csid,'. elapsedtime',elapsedtime
    f['subjectCsid'] = csid 
    print "movements REST API post succeeded..."

    uri     = 'relations'

    payload = relationsPayload(f)
    print "posting to relations REST API...obj2inv"
    (url,data,csid,elapsedtime) =  postxml('POST',uri,realm,hostname,username,password,payload)
    print 'got csid',csid,'. elapsedtime',elapsedtime
    print "relations REST API post succeeded..."

    # reverse the roles
    temp =  f['objectCsid']
    f['objectCsid']          =  f['subjectCsid']
    f['subjectCsid']         =  temp
    f['subjectDocumentType'] = 'CollectionObject'
    f['objectDocumentType']  = 'Movement'
    payload = relationsPayload(f)
    print "posting to relations REST API...inv2obj"
    (url,data,csid,elapsedtime) = postxml('POST',uri,realm,hostname,username,password,payload)
    print 'got csid',csid,'. elapsedtime',elapsedtime
    print "relations REST API post succeeded..."
