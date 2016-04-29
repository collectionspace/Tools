#!/usr/bin/env /usr/bin/python
# -*- coding: UTF-8 -*-

import os
import sys
import copy

# for log
import csv
import codecs
import ConfigParser
import collections

import time, datetime
import httplib, urllib2
import cgi
#import cgitb; cgitb.enable()  # for troubleshooting
import re

import cswaSMBclient

MAXLOCATIONS = 1000

try:
    import xml.etree.ElementTree as etree
    #print("running with ElementTree")
except ImportError:
    try:
        from lxml import etree
        #print("running with lxml.etree")
    except ImportError:
        try:
            # normal cElementTree install
            import cElementTree as etree
            #print("running with cElementTree")
        except ImportError:
            try:
                # normal ElementTree install
                import elementtree.ElementTree as etree
                #print("running with ElementTree")
            except ImportError:
                print("Failed to import ElementTree from any known place")

# the only other module: isolate postgres calls and connection
import cswaDB as cswaDB
import cswaConstants as cswaConstants
import cswaGetAuthorityTree as cswaGetAuthorityTree
import cswaConceptutils as concept
import cswaCollectionUtils as cswaCollectionUtils


# updateactionlabel = config.get('info', 'updateactionlabel')
# updateType = config.get('info', 'updatetype')
# institution = config.get('info','institution')

#if not validateParameters(form, config): return

## {{{ http://code.activestate.com/recipes/81547/ (r1)
def cgiFieldStorageToDict(fieldStorage):
    """Get a plain dictionary, rather than the '.value' system used by the cgi module."""
    params = {}
    for key in fieldStorage.keys():
        #sys.stderr.write('%-13s:: %s' % ('key:',key))
        params[key] = fieldStorage[key].value
    return params


def getConfig(form):
    try:
        fileName = form.get('webapp') + '.cfg'
        config = ConfigParser.RawConfigParser()
        config.read(os.path.join('../cfgs',fileName))
        # test to see if it seems like it is really a config file
        updateType = config.get('info', 'updatetype')
        return config
    except:
        return False

def getCreds(form):
    username = form.get('csusername')
    password = form.get('cspassword')
    return username, password

def authenticateUser(username, password, form, config):
    realm = config.get('connect', 'realm')
    hostname = config.get('connect', 'hostname')
    uri = "accounts/0/accountperms"
    sys.stderr.write('%-13s:: %s\n' % ('creds:',username))
    try:
        url, content, elapsedtime = getxml(uri, realm, hostname, username, password, None)
        return True
    except:
        return False



def serverCheck(form, config):
    result = '<tr><td class="zcell">start server check</td><td class="zcell">' + time.strftime("%b %d %Y %H:%M:%S", time.localtime()) + "</td></tr>"

    elapsedtime = time.time()
    # do an sql search...
    result += '<tr><td class="zcell">SQL check</td><td class="zcell">' + cswaDB.testDB(config) + "</td></tr>"
    elapsedtime = time.time() - elapsedtime
    result += '<tr><td class="zcell">SQL time</td><td class="zcell">' + ('%8.2f' % elapsedtime) + " seconds</td></tr>"

    # if we are configured for barcodes, try that...
    try:
        config.get('files', 'cmdrfileprefix') + config.get('files', 'cmdrauditfile')
        try:
            elapsedtime = time.time()
            result += '<tr><td class="zcell">barcode audit file</td><td class="zcell">' + config.get('files', 'cmdrauditfile') + "</td></tr>"
            result += '<tr><td class="zcell">trying...</td><td class="zcell"> to write empty test files to commanderWatch directory</td></tr>'
            printers, selected, printerlist = cswaConstants.getPrinters(form)
            for printer in printerlist:
                result += ('<tr><td class="zcell">location labels @ %s</td><td class="zcell">' % printer[1]) + writeCommanderFile('test', printer[1], 'locationLabels', 'locations',  [], config) + "</td></tr>"
                result += ('<tr><td class="zcell">object labels @ %s</td><td class="zcell">' % printer[1]) + writeCommanderFile('test', printer[1], 'objectLabels', 'objects', [], config) + "</td></tr>"
            elapsedtime = time.time() - elapsedtime
            result += '<tr><td class="zcell">barcode check time</td><td class="zcell">' + ('%8.2f' % elapsedtime) + " seconds</td></tr>"
        except:
            result += '<tr><td class="zcell">barcode functionality check</td><td class="zcell"><span class="error">FAILED.</span></td></tr>'
    except:
        result += '<tr><td class="zcell">barcode functionality check</td><td class="zcell">skipped, not configured in config file.</td></tr>'

    elapsedtime = time.time()
    # rest check...
    elapsedtime = time.time() - elapsedtime
    result += '<tr><td class="zcell">REST check</td><td class="zcell">Not ready yet.</td></tr>'
    #result += "<tr><td class="zcell">REST check</td><td class="zcell">" + ('%8.2f' % elapsedtime) + " seconds</td></tr>"

    result += '<tr><td class="zcell">end server check</td><td class="zcell">' + time.strftime("%b %d %Y %H:%M:%S", time.localtime()) + "</td></tr>"
    result += '''<tr><td colspan="2"><hr/></td></tr>'''

    return '''<table><tbody><tr><td><h3>Server Status Check</h3></td></tr>''' + result + '''</tbody></table>'''


def handleTimeout(source, form):
    print '<h3><span class="error">Time limit exceeded! The problem has been logged and will be examined. Feel free to try again though!</span></h3>'
    sys.stderr.write('TIMEOUT::' + source + '::location::' + str(form.get("lo.location1")) + '::')
    raise


def validateParameters(form, config):
    valid = True

    if form.get('handlerRefName') == 'None':
        print '<h3>Please select a handler before searching</h3>'
        valid = False

    #if not str(form.get('num2ret')).isdigit():
    #    print '<h3><i>number to retrieve</i> must be a number, please!</h3>'
    #    valid = False

    if form.get('reason') == 'None':
        print '<h3>Please select a reason before searching</h3>'
        valid = False

    if config.get('info', 'updatetype') == 'barcodeprint':
        if form.get('printer') == 'None':
            print '<h3>Please select a printer before trying to print labels</h3>'
            valid = False

    prohibitedLocations = cswaConstants.getProhibitedLocations(config)
    if form.get("lo.location1"):
        loc = form.get("lo.location1")
        if loc in prohibitedLocations:
            print '<h3>Location "%s" is unavailable to this webapp. Please contact registration staff for details.</h3>' % form.get(
                "lo.location1")
            valid = False

    if form.get("lo.location2"):
        loc = form.get("lo.location2")
        if loc in prohibitedLocations:
            print '<h3>Location "%s" is unavailable to this webapp. Please contact registration staff for details.</h3>' % form.get(
                "lo.location2")
            valid = False

    return valid


def search(form, config):
    mapping = {'lo.location1': 'l1', 'lo.location2': 'l2', 'ob.objectnumber': 'ob', 'cp.place': 'pl',
               'co.concept': 'co'}
    for m in mapping.keys():
        if form.get(m) == None:
            pass
        else:
            print '%s : %s %s\n' % (m, mapping[m], form.get(m))

def makeGroup(form,config):
    pass


def doRelationsEdit(form,config):
    pass


def doRelationsSearch(form, config):
    pass


def doComplexSearch(form, config, displaytype):
    #if not validateParameters(form,config): return
    listAuthorities('taxon', 'TaxonTenant35', form.get("ut.taxon"), config, form, displaytype)
    listAuthorities('locations', 'Locationitem', form.get("lo.location1"), config, form, displaytype)
    listAuthorities('places', 'Placeitem', form.get("px.place"), config, form, displaytype)
    #listAuthorities('taxon',     'TaxonTenant35',  form.get("ob.objectnumber"),config, form, displaytype)
    #listAuthorities('concepts',  'TaxonTenant35',  form.get("cx.concept"),     config, form, displaytype)

    getTableFooter(config, displaytype, '')


def listAuthorities(authority, primarytype, authItem, config, form, displaytype):
    if authItem == None or authItem == '': return
    rows = cswaGetAuthorityTree.getAuthority(authority, primarytype, authItem, config.get('connect', 'connect_string'))

    listSearchResults(authority, config, displaytype, form, rows)

    return rows


def doLocationSearch(form, config, displaytype):
    if not validateParameters(form, config): return
    updateType = config.get('info', 'updatetype')

    try:
        #If barcode print, assume empty end location is start location
        if updateType == "barcodeprint":
            if form.get("lo.location2"):
                rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), 500, config)
            else:
                rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location1"), 500, config)
        else:
            rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), MAXLOCATIONS, config)
    except:
        raise

    hasDups = listSearchResults('locations', config, displaytype, form, rows)

    if hasDups:
        getTableFooter(config, 'error', 'Please eliminate duplicates and try again!')
        return
    if len(rows) != 0: getTableFooter(config, displaytype, '')



def doProcedureSearch(form, config, displaytype):
    if not validateParameters(form, config): return

    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')
    updateactionlabel = config.get('info', 'updateactionlabel')

    if updateType == 'intake':
        crate = verifyLocation(form.get("lo.crate"), form, config)
        toLocation = verifyLocation(form.get("lo.location1"), form, config)

        if str(form.get("lo.crate")) != '' and crate == '':
            print '<span style="color:red;">Crate is not valid! Sorry!</span><br/>'
        if toLocation == '':
            print '<span style="color:red;">Destination is not valid! Sorry!</span><br/>'
        if (str(form.get("lo.crate")) != '' and crate == '') or toLocation == '':
            return

        toRefname = cswaDB.getrefname('locations_common', toLocation, config)
        toCrate = cswaDB.getrefname('locations_common', crate, config)

    try:
        rows = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno2"), 500, config)
    except:
        raise

    if len(rows) == 0:
        print '<span style="color:red;">No objects in this range! Sorry!</span>'
    else:
        totalobjects = 0
        if updateType == 'objinfo':
            print cswaConstants.infoHeaders(form.get('fieldset'))
        else:
            print cswaConstants.getHeader(updateType,institution)
        for r in rows:
            totalobjects += 1
            print formatRow({'rowtype': updateType, 'data': r}, form, config)

        print '\n</table><hr/><table width="100%"'
        print """<tr><td align="center" colspan="3">"""
        msg = "Caution: clicking on the button at left will update <b>ALL %s objects</b> shown on this page!" % totalobjects
        print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="3">%s</td></tr>''' % msg
        print "\n</table><hr/>"

        if updateType == 'moveobject':
            print '<input type="hidden" name="toRefname" value="%s">' % toRefname
            print '<input type="hidden" name="toCrate" value="%s">' % toCrate
            print '<input type="hidden" name="toLocAndCrate" value="%s: %s">' % (toLocation, crate)


def doObjectSearch(form, config, displaytype):
    if not validateParameters(form, config): return
    if form.get('ob.objno1') == '':
        print '<h3>Please enter a starting object number!</h3><hr>'
        return

    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')
    updateactionlabel = config.get('info', 'updateactionlabel')

    if updateType == 'moveobject':
        crate = verifyLocation(form.get("lo.crate"), form, config)
        toLocation = verifyLocation(form.get("lo.location1"), form, config)

        if str(form.get("lo.crate")) != '' and crate == '':
            print '<span style="color:red;">Crate is not valid! Sorry!</span><br/>'
        if toLocation == '':
            print '<span style="color:red;">Destination is not valid! Sorry!</span><br/>'
        if (str(form.get("lo.crate")) != '' and crate == '') or toLocation == '':
            return

        toRefname = cswaDB.getrefname('locations_common', toLocation, config)
        toCrate = cswaDB.getrefname('locations_common', crate, config)

    try:
        rows = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno2"), 500, config)
    except:
        raise

    if len(rows) == 0:
        print '<span style="color:red;">No objects in this range! Sorry!</span>'
    else:
        totalobjects = 0
        if updateType == 'objinfo':
            print cswaConstants.infoHeaders(form.get('fieldset'))
        else:
            print cswaConstants.getHeader(updateType,institution)
        for r in rows:
            totalobjects += 1
            print formatRow({'rowtype': updateType, 'data': r}, form, config)

        print '\n</table><hr/><table width="100%"'
        print """<tr><td align="center" colspan="3">"""
        msg = "Caution: clicking on the button at left will update <b>ALL %s objects</b> shown on this page!" % totalobjects
        print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="3">%s</td></tr>''' % msg
        print "\n</table><hr/>"

        if updateType == 'moveobject':
            print '<input type="hidden" name="toRefname" value="%s">' % toRefname
            print '<input type="hidden" name="toCrate" value="%s">' % toCrate
            print '<input type="hidden" name="toLocAndCrate" value="%s: %s">' % (toLocation, crate)



def doOjectRangeSearch(form, config, displaytype=''):
    if not validateParameters(form, config): return

    updateType = config.get('info', 'updatetype')
    updateactionlabel = config.get('info', 'updateactionlabel')

    try:
        if form.get('ob.objno2'):
            objs = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno2"), 1000, config)
        else:
            objs = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno1"), 1000, config)
    except:
        raise
    print """
    <table><tr>
    <th>Object</th>
    <th>Count</th>
    <th>Object Name</th>
    <th>Culture</th>
    <th>Collection Place</th>
    <th>Ethnographic File Code</th>
    </tr>"""
    for o in objs:
        print '''<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>''' % (o[3], o[5], o[4], o[7], o[6], o[9])

    print """<tr><td align="center" colspan="6"><hr></td></tr>"""
    print """<tr><td align="center" colspan="6"><b>%s objects</b></td></tr>""" % len(objs)
    print """<tr><td align="center" colspan="6">"""
    print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td></tr>'''


def listSearchResults(authority, config, displaytype, form, rows):
    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')
    hasDups = False

    if not rows: rows = []
    rows.sort()
    rowcount = len(rows)

    label = authority
    if label[-1] == 's' and rowcount == 1: label = label[:-1]
    if label == 'taxon' and rowcount > 1: label = 'taxa'

    if displaytype == 'silent':
        print """<table>"""
    elif displaytype == 'select':
        print """<div style="float:left; width: 300px;">%s %s in this range</th>""" % (rowcount, label)
    else:
        if updateType == 'barcodeprint':
            rows.reverse()
            count = 0
            objectsHandled = []
            for r in rows:
                objects = cswaDB.getlocations(r[0], '', 1, config, updateType,institution)
                for o in objects:
                    if o[3] + o[4] in objectsHandled:
                        objects.remove(o)
                    else:
                        objectsHandled.append(o[3] + o[4])
                count += len(objects)
            print """
    <table width="100%%">
    <tr>
      <th>%s %s and %s objects in this range</th>
    </tr>""" % (rowcount, label, count)
        else:
            print """
    <table width="100%%">
    <tr>
      <th>%s %s in this range</th>
    </tr>""" % (rowcount, label)

    if rowcount == 0:
        print "</table>"
        return

    if displaytype == 'select':
        print """<li><input type="checkbox" name="select-%s" id="select-%s" checked/> select all</li>""" % (
            authority, authority)

    if displaytype == 'list' or displaytype == 'select':
        rowtype = 'location'
        if displaytype == 'select': rowtype = 'select'
        duplicates = []
        for r in rows:
	    #print "<b>r = </b>",r
            if r[1] in duplicates:
                hasDups = True
                #r.append('')
                # r.append('Duplicate!')
            else:
                #r.append('')
                #duplicates.append(r[1])
                pass
            print formatRow({'boxtype': authority, 'rowtype': rowtype, 'data': r}, form, config)

    elif displaytype == 'nolist':
        label = authority
        if label[-1] == 's': label = label[:-1]
        if rowcount == 1:
            print '<tr><td class="authority">%s</td></tr>' % (rows[0][0])
        else:
            print '<tr><th>first %s</th><td class="authority">%s</td></tr>' % (label, rows[0][0])
            print '<tr><th>last %s</th><td class="authority">%s</td></tr>' % (label, rows[-1][0])

    if displaytype == 'select':
        print "\n</div>"
    else:
        print "</table>"
        #print """<input type="hidden" name="count" value="%s">""" % rowcount

    return hasDups


def getTableFooter(config, displaytype, msg):
    updateType = config.get('info', 'updatetype')

    print """<table width="100%"><tr><td align="center" colspan="3"><hr></tr>"""
    if displaytype == 'error':
        print """<tr><td align="center"><span style="color:red;"><b>%s</b></span></td></tr>""" % msg
    elif displaytype == 'list':
        print """<tr><td align="center">"""
        button = 'Enumerate Objects'
        print """<input type="submit" class="save" value="%s" name="action"></td>""" % button
        if updateType == "packinglist":
            print """<td><input type="submit" class="save" value="%s" name="action"></td>""" % 'Download as CSV'
        else:
            print "<td></td>"
        print "</tr>"
    else:
        print """<tr><td align="center">"""
        button = config.get('info', 'updateactionlabel')
        print """<input type="submit" class="save" value="%s" name="action"></td>""" % button
        if updateType == "packinglist":
            print """<td><input type="submit" class="save" value="%s" name="action"></td>""" % 'Download as CSV'
        if updateType == "barcodeprint":
            print """<td><input type="submit" class="save" value="%s" name="action"></td>""" % 'Create Labels for Locations Only'
        else:
            print "<td></td>"
        print "</tr>"
    print "</table><hr/>"


def doEnumerateObjects(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')

    if not validateParameters(form, config): return

    try:
        locationList = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), MAXLOCATIONS,
                                         config)
    except:
        raise

    rowcount = len(locationList)

    if rowcount == 0:
        print '<h2>No locations in this range!</h2>'
        return

    if updateType == 'keyinfo' or updateType == 'objinfo':
        print cswaConstants.infoHeaders(form.get('fieldset'))
    else:
        print cswaConstants.getHeader(updateType,institution)
    totalobjects = 0
    totallocations = 0
    for l in locationList:

        try:
            objects = cswaDB.getlocations(l[0], '', 1, config, updateType,institution)
        except:
            raise

        rowcount = len(objects)
        locations = {}
        if rowcount == 0:
            locationheader = formatRow({'rowtype': 'subheader', 'data': l}, form, config)
            locations[locationheader] = ['<tr><td colspan="3">No objects found at this location.</td></tr>']
        for r in objects:
            locationheader = formatRow({'rowtype': 'subheader', 'data': r}, form, config)
            if locationheader in locations:
                pass
            else:
                locations[locationheader] = []
                totallocations += 1

            totalobjects += 1
            locations[locationheader].append(formatRow({'rowtype': updateType, 'data': r}, form, config))

        locs = locations.keys()
        locs.sort()
        for header in locs:
            print header
            print '\n'.join(locations[header])


    print "\n</table>\n"
    if totalobjects == 0:
        pass
    else:
        print "<hr/>"
        print '\n<table width="100%">\n'
        print """<tr><td align="center" colspan="3">"""
        if updateType == 'keyinfo' or updateType == 'objinfo':
            msg = "Caution: clicking on the button at left will revise the above fields for <b>ALL %s objects</b> shown in these %s locations!" % (
                totalobjects, totallocations)
        else:
            msg = "Caution: clicking on the button at left will change the " + updateType + " of <b>ALL %s objects</b> shown in these %s locations!" % (
                totalobjects, totallocations)
        print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="4">%s</td></tr>''' % msg
        print "\n</table><hr/>"


def verifyLocation(loc, form, config):
    location = cswaDB.getloclist('exact', loc, '', 1, config)
    if location == [] : return
    if loc == location[0][0]:
        return loc
    else:
        return ''

def doCheckMove(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')

    if not validateParameters(form, config): return

    crate = verifyLocation(form.get("lo.crate"), form, config)
    fromLocation = verifyLocation(form.get("lo.location1"), form, config)
    toLocation = verifyLocation(form.get("lo.location2"), form, config)

    toRefname = cswaDB.getrefname('locations_common', toLocation, config)

    #sys.stderr.write('%-13s:: %-18s:: %s\n' % (updateType, 'toRefName', toRefname))

    # DEBUG
    #print '<table cellpadding="8px" border="1">'
    #print '<tr><td>%s</td><td>%s</td></tr>' % ('From',fromLocation)
    #print '<tr><td>%s</td><td>%s</td></tr>' % ('Crate',crate)
    #print '<tr><td>%s</td><td>%s</td></tr>' % ('To',toLocation)
    #print '</table>'

    if crate == '':
        print '<span style="color:red;">Crate is not valid! Sorry!</span><br/>'
    if fromLocation == '':
        print '<span style="color:red;">From location is not valid! Sorry!</span><br/>'
    if toLocation == '':
        print '<span style="color:red;">To location is not valid! Sorry!</span><br/>'
    if crate == '' or fromLocation == '' or toLocation == '':
        return

    try:
        # NB: the movecrate webapp uses the inventory query...naturally!
        objects = cswaDB.getlocations(form.get("lo.location1"), '', 1, config, 'inventory',institution)
    except:
        raise

    locations = {}
    if len(objects) == 0:
        print '<span style="color:red;">No objects found at this location! Sorry!</span>'
        return

    totalobjects = 0
    totallocations = 0

    #sys.stderr.write('%-13s:: %s :: %-18s:: %s\n' % (updateType, crate, 'objects', len(objects)))
    for r in objects:
        if r[15] != crate: # skip if this is not the crate we want
            continue
        #sys.stderr.write('%-13s:: %-18s:: %s\n' % (updateType,  r[15],  r[0]))
        locationheader = formatRow({'rowtype': 'subheader', 'data': r}, form, config)
        if locations.has_key(locationheader):
            pass
        else:
            locations[locationheader] = []
            totallocations += 1

        totalobjects += 1
        locations[locationheader].append(formatRow({'rowtype': 'inventory', 'data': r}, form, config))

    locs = locations.keys()
    locs.sort()

    if len(locs) == 0:
        print '<span style="color:red;">Did not find this crate at this location! Sorry!</span>'
        return

    print cswaConstants.getHeader(updateType,institution)
    for header in locs:
        print header
        print '\n'.join(locations[header])

    print """<tr><td align="center" colspan="6"><hr><td></tr>"""
    print """<tr><td align="center" colspan="3">"""
    msg = "Caution: clicking on the button at left will move <b>ALL %s objects</b> shown in this crate!" % totalobjects
    print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="3">%s</td></tr>''' % msg

    print "\n</table><hr/>"
    print '<input type="hidden" name="toRefname" value="%s">' % toRefname
    print '<input type="hidden" name="toLocAndCrate" value="%s: %s">' % (toLocation, crate)


def doCheckPowerMove(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')

    if not validateParameters(form, config): return

    crate1 = verifyLocation(form.get("lo.crate1"), form, config)
    crate2 = verifyLocation(form.get("lo.crate2"), form, config)

    if crate1 == '':
        print '<span style="color:red;">From Crate is not valid! Sorry!</span><br/>'
    if crate2 == '':
        print '<span style="color:red;">To Crate is not valid! Sorry!</span><br/>'

    fromLocation = verifyLocation(form.get("lo.location1"), form, config)
    toLocation = verifyLocation(form.get("lo.location2"), form, config)

    if fromLocation == '':
        print '<span style="color:red;">From location is not valid! Sorry!</span><br/>'
    if toLocation == '':
        print '<span style="color:red;">To location is not valid! Sorry!</span><br/>'
    if fromLocation == '' or toLocation == '':
        return

    toLocRefname = cswaDB.getrefname('locations_common', toLocation, config)
    toCrateRefname = cswaDB.getrefname('locations_common', crate2, config)
    fromRefname = cswaDB.getrefname('locations_common', fromLocation, config)

    #sys.stderr.write('%-13s:: %-18s:: %s\n' % (updateType, 'toRefName', toRefname))

    # DEBUG
    #print '<table cellpadding="8px" border="1">'
    #print '<tr><td>%s</td><td>%s</td></tr>' % ('From',fromLocation)
    #print '<tr><td>%s</td><td>%s</td></tr>' % ('Crate',crate)
    #print '<tr><td>%s</td><td>%s</td></tr>' % ('To',toLocation)
    #print '</table>'

    try:
        # NB: the movecrate webapp uses the inventory query...naturally!
        objects = cswaDB.getlocations(form.get("lo.location1"), '', 1, config, 'inventory',institution)
    except:
        raise

    locations = {}
    if len(objects) == 0:
        print '<span style="color:red;">No objects found at this location! Sorry!</span>'
        return

    totalobjects = 0
    totallocations = 0

    #sys.stderr.write('%-13s:: %s :: %-18s:: %s\n' % (updateType, crate, 'objects', len(objects)))
    for r in objects:
        if r[15] != crate1 and crate1 != '': # skip if this is not the crate we want
                continue
        #sys.stderr.write('%-13s:: %-18s:: %s\n' % (updateType,  r[15],  r[0]))
        locationheader = formatRow({'rowtype': 'subheader', 'data': r}, form, config)
        if locations.has_key(locationheader):
            pass
        else:
            locations[locationheader] = []
            totallocations += 1

        totalobjects += 1
        locations[locationheader].append(formatRow({'rowtype': 'powermove', 'data': r}, form, config))

    locs = locations.keys()
    locs.sort()

    if len(locs) == 0:
        print '<span style="color:red;">Did not find this crate at this location! Sorry!</span>'
        return

    print cswaConstants.getHeader(updateType,institution)
    for header in locs:
        print header
        print '\n'.join(locations[header])

    print """<tr><td align="center" colspan="6"><hr><td></tr>"""
    print """<tr><td align="center" colspan="3">"""
    msg = "Caution: clicking on the button at left will move <b>ALL %s objects</b> shown in this crate!" % totalobjects
    print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="3">%s</td></tr>''' % msg

    print "\n</table><hr/>"
    if crate2 is None: crate2 = ''
    print '<input type="hidden" name="toRefname" value="%s">' % toLocRefname
    print '<input type="hidden" name="toLocAndCrate" value="%s: %s">' % (toLocation, crate2)
    print '<input type="hidden" name="toCrate" value="%s">' % toCrateRefname

def doBulkEdit(form, config):

    if not validateParameters(form, config): return

    updateType = config.get('info', 'updatetype')
    updateactionlabel = config.get('info', 'updateactionlabel')

    try:
        if form.get('ob.objno2'):
            objs = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno2"), 3000, config)
        else:
            objs = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno1"), 3000, config)
    except:
        objs = []


    CSIDs = []
    fieldset = form.get('fieldset')
    for row in objs:
        CSIDs.append(row[8])

    refNames2find = {}

    index = 'user'
    if fieldset == 'namedesc':
        pass
    elif fieldset == 'registration':
        if not refNames2find.has_key(form.get('ant.' + index)):
            refNames2find[form.get('ant.' + index)] = cswaDB.getrefname('pahmaaltnumgroup_type', form.get('ant.' + index), config)
        if not refNames2find.has_key(form.get('pc.' + index)):
            refNames2find[form.get('pc.' + index)] = cswaDB.getrefname('collectionobjects_common_fieldcollectors', form.get('pc.' + index), config)
        if not refNames2find.has_key(form.get('pd.' + index)):
            refNames2find[form.get('pd.' + index)] = cswaDB.getrefname('acquisitions_common_owners', form.get('pd.' + index), config)
    elif fieldset == 'keyinfo':
        if not refNames2find.has_key(form.get('cp.' + index)):
            refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
        if not refNames2find.has_key(form.get('cg.' + index)):
            refNames2find[form.get('cg.' + index)] = cswaDB.getrefname('concepts_common', form.get('cg.' + index), config)
        if not refNames2find.has_key(form.get('fc.' + index)):
            refNames2find[form.get('fc.' + index)] = cswaDB.getrefname('concepts_common', form.get('fc.' + index), config)
    elif fieldset == 'hsrinfo':
        if not refNames2find.has_key(form.get('cp.' + index)):
            refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
    elif fieldset == 'objtypecm':
        if not refNames2find.has_key(form.get('cp.' + index)):
            refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
    else:
        pass
        #error! fieldset not set!

    doTheUpdate(CSIDs, form, config, fieldset, refNames2find)



def doBulkEditForm(form, config, displaytype):
    #print form
    if not validateParameters(form, config): return

    updateType = config.get('info', 'updatetype')
    updateactionlabel = config.get('info', 'updateactionlabel')

    try:
        if form.get('ob.objno2'):
            objs = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno2"), 3000, config)
        else:
            objs = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno1"), 3000, config)
    except:
        objs = []

    totalobjects = len(objs)

    print '''<table width="100%" cellpadding="8px"><tbody><tr class="smallheader">
      <td width="250px">Field</td>
      <td>Value to Set</td></tr>'''

    print formatInfoReviewForm(form)

    print '</table>'
    print '<table>'

    msg = "Caution: clicking on the button at left will update <b>ALL %s objects</b> in this range!" % totalobjects
    print """<tr><td align="center" colspan="3"><hr></tr>"""
    print """<tr><td align="center" colspan="2">"""
    print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="1">%s</td></tr>''' % msg


    print '</table>'
    print "<hr/>"


def doSetupIntake(form, config):

    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')
    updateactionlabel = config.get('info', 'updateactionlabel')

    print '<table width="100%">'
    print formatRow({'rowtype': 'subheader', 'data': ['Intake Values']}, form, config)

    print cswaConstants.getHeader('intakeValues',institution)

    # get numbobjects
    numobjects = 1
    for i in cswaConstants.getIntakeFields('intake'):
        if i[2] == 'numobjects':
            try:
                numobjects = int(form.get(i[2]))
            except:
                pass

    for i,box in enumerate(cswaConstants.getIntakeFields('intake')):
        if box[2] == 'dummy':
            continue
        if box[4] == 'fixed':
            if box[2] == 'tr':
                if numobjects == 1:
                    objectrange = '1'
                else:
                    objectrange = '1-' + str(numobjects)
                computedresult = 'TR. ' + form.get(box[2]) + '.14.' + objectrange
                print '<tr><th class="zcell">%s</th><td>%s</td></tr>' % (box[0],computedresult)
            else:
                print '<tr><th class="zcell">%s</th><td>%s</td></tr>' % (box[0],form.get(box[2]))
        else:
            print '<tr><th class="zcell">%s</th><td>%s</td></tr>' % (box[0],form.get(box[2]))

    print formatRow({'rowtype': 'subheader', 'data': ['Basic Collection Object Info']}, form, config)

    objectDescriptions = cswaConstants.getIntakeFields('objects')

    #print "<tr>"
    #for o in objectDescriptions:
    #    print '<th>%s</th>' % o[0]
    #print "</tr>"

    for row in range(numobjects):
        print '<tr>'
        for i,box in enumerate(objectDescriptions):
            if i % 5 == 0:
                print "</tr><tr>"
            print '''
            <td>%s<br/>
            <input id="%s.%s" class="xspan" type="%s" size="%s" name="%s.%s" value="%s"></td>
            ''' % (box[0],box[2],row,box[4],box[1],box[2],row,box[3])
        print '</tr>'
        print '<tr><td colspan="7"><hr/></td></tr>'

    print '\n</table><hr/><table width="100%"'
    print """<tr><td align="center" colspan="3">"""
    msg = "Caution: clicking on the button at left will create <b>intake and %s object records</b> as entered on this page!" % numobjects
    print '''<input type="submit" class="save" value="''' + updateactionlabel + '''" name="action"></td><td  colspan="3">%s</td></tr>''' % msg
    print "\n</table><hr/>"



def doCommitIntake(form, config):
    pass

def doUpdateKeyinfo(form, config):
    #print form
    CSIDs = []
    fieldset = form.get('fieldset')
    for i in form:
        if 'csid.' in i:
            CSIDs.append(form.get(i))

    refNames2find = {}
    for row, csid in enumerate(CSIDs):

        index = csid # for now, the index is the csid
        if fieldset == 'namedesc':
            pass
        elif fieldset == 'registration':
            if not refNames2find.has_key(form.get('ant.' + index)):
                refNames2find[form.get('ant.' + index)] = cswaDB.getrefname('pahmaaltnumgroup_type', form.get('ant.' + index), config)
            if not refNames2find.has_key(form.get('pc.' + index)):
                refNames2find[form.get('pc.' + index)] = cswaDB.getrefname('collectionobjects_common_fieldcollectors', form.get('pc.' + index), config)
            if not refNames2find.has_key(form.get('pd.' + index)):
                refNames2find[form.get('pd.' + index)] = cswaDB.getrefname('acquisitions_common_owners', form.get('pd.' + index), config)
        elif fieldset == 'keyinfo':
            if not refNames2find.has_key(form.get('cp.' + index)):
                refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
            if not refNames2find.has_key(form.get('cg.' + index)):
                refNames2find[form.get('cg.' + index)] = cswaDB.getrefname('concepts_common', form.get('cg.' + index), config)
            if not refNames2find.has_key(form.get('fc.' + index)):
                refNames2find[form.get('fc.' + index)] = cswaDB.getrefname('concepts_common', form.get('fc.' + index), config)
        elif fieldset == 'hsrinfo':
            if not refNames2find.has_key(form.get('cp.' + index)):
                refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
        elif fieldset == 'objtypecm':
            if not refNames2find.has_key(form.get('cp.' + index)):
                refNames2find[form.get('cp.' + index)] = cswaDB.getrefname('places_common', form.get('cp.' + index), config)
        else:
            pass
            #error! fieldset not set!

    doTheUpdate(CSIDs, form, config, fieldset, refNames2find)


def doTheUpdate(CSIDs, form, config, fieldset, refNames2find):

    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')

    print cswaConstants.getHeader('keyinfoResult',institution)

    #for r in refNames2find:
    #    print '<tr><td>%s<td>%s<td>%s</tr>' % ('refname',refNames2find[r],r)
    #print CSIDs

    numUpdated = 0
    for row, csid in enumerate(CSIDs):

        if updateType == 'bulkedit':
            index = 'user'
        else:
            index = csid
        updateItems = {}
        updateItems['objectCsid'] = csid
        updateItems['objectName'] = form.get('onm.' + index)
        #updateItems['objectNumber'] = form.get('oox.' + index)
        if fieldset == 'namedesc':
            updateItems['briefDescription'] = form.get('bdx.' + index)
        elif fieldset == 'registration':
            updateItems['pahmaAltNum'] = form.get('anm.' + index)
            updateItems['pahmaAltNumType'] = form.get('ant.' + index)
            updateItems['fieldCollector'] = refNames2find[form.get('pc.' + index)]
        elif fieldset == 'keyinfo':
            if form.get('ocn.' + index) != '':
                updateItems['objectCount'] = form.get('ocn.' + index)
            updateItems['pahmaFieldCollectionPlace'] = refNames2find[form.get('cp.' + index)]
            updateItems['assocPeople'] = refNames2find[form.get('cg.' + index)]
            updateItems['pahmaEthnographicFileCode'] = refNames2find[form.get('fc.' + index)]
        elif fieldset == 'hsrinfo':
            if form.get('ocn.' + index) != '':
                updateItems['objectCount'] = form.get('ocn.' + index)
            updateItems['inventoryCount'] = form.get('ctn.' + index)
            updateItems['pahmaFieldCollectionPlace'] = refNames2find[form.get('cp.' + index)]
            updateItems['briefDescription'] = form.get('bdx.' + index)
        elif fieldset == 'objtypecm':
            if form.get('ocn.' + index) != '':
                updateItems['objectCount'] = form.get('ocn.' + index)
            updateItems['collection'] = form.get('ot.' + index)
            updateItems['responsibleDepartment'] = form.get('cm.' + index)
            updateItems['pahmaFieldCollectionPlace'] = refNames2find[form.get('cp.' + index)]
        elif fieldset == 'placeanddate':
            updateItems['pahmaFieldLocVerbatim'] = form.get('vfcp.' + index)
            updateItems['pahmaFieldCollectionDate'] = form.get('cd.' + index)
        else:
            pass
            #error!

        for i in ('handlerRefName',):
            updateItems[i] = form.get(i)

        #print updateItems
        msg = 'updated. '
        if fieldset == 'keyinfo':
            if updateItems['pahmaFieldCollectionPlace'] == '' and form.get('cp.' + index):
                if form.get('cp.' + index) == cswaDB.getCSIDDetail(config, index, 'fieldcollectionplace'):
                    pass
                else:
                    msg += '<span style="color:red;"> Field Collection Place: term "%s" not found, field not updated.</span>' % form.get('cp.' + index)
            if updateItems['assocPeople'] == '' and form.get('cg.' + index):
                if form.get('cg.' + index) == cswaDB.getCSIDDetail(config, index, 'assocpeoplegroup'):
                    pass
                else:
                    msg += '<span style="color:red;"> Cultural Group: term "%s" not found, field not updated.</span>' % form.get('cg.' + index)
            if updateItems['pahmaEthnographicFileCode'] == '' and form.get('fc.' + index):
                msg += '<span style="color:red;"> Ethnographic File Code: term "%s" not found, field not updated.</span>' % form.get('fc.' + index)
            if 'objectCount' in updateItems:
                try:
                    int(updateItems['objectCount'])
                    int(updateItems['objectCount'][0])
                except ValueError:
                    msg += '<span style="color:red;"> Object count: "%s" is not a valid number!</span>' % form.get('ocn.' + index)
                    del updateItems['objectCount']
        elif fieldset == 'registration':
            if updateItems['fieldCollector'] == '' and form.get('pc.' + index):
                msg += '<span style="color:red;"> Field Collector: term "%s" not found, field not updated.</span>' % form.get('pc.' + index)
        elif fieldset == 'hsrinfo':
            if updateItems['pahmaFieldCollectionPlace'] == '' and form.get('cp.' + index):
                if form.get('cp.' + index) == cswaDB.getCSIDDetail(config, index, 'fieldcollectionplace'):
                    pass
                else:
                    msg += '<span style="color:red;"> Field Collection Place: term "%s" not found, field not updated.</span>' % form.get('cp.' + index)
            if 'objectCount' in updateItems:
                try:
                    int(updateItems['objectCount'])
                    int(updateItems['objectCount'][0])
                except ValueError:
                    msg += '<span style="color:red;"> Object count: "%s" is not a valid number!</span>' % form.get('ocn.' + index)
                    del updateItems['objectCount']
        elif fieldset == 'objtypecm':
            if updateItems['pahmaFieldCollectionPlace'] == '' and form.get('cp.' + index):
                if form.get('cp.' + index) == cswaDB.getCSIDDetail(config, index, 'fieldcollectionplace'):
                    pass
                else:
                    msg += '<span style="color:red;"> Field Collection Place: term "%s" not found, field not updated.</span>' % form.get('cp.' + index)
            if 'objectCount' in updateItems:
                try:
                    int(updateItems['objectCount'])
                    int(updateItems['objectCount'][0])
                except ValueError:
                    msg += '<span style="color:red;"> Object count: "%s" is not a valid number!</span>' % form.get('ocn.' + index)
                    del updateItems['objectCount']
        elif fieldset == 'placeanddate':
            # msg += 'place and date'
            pass

        updateMsg = ''
        for item in updateItems.keys():
            if updateItems[item] == 'None' or updateItems[item] is None:
                if item in 'collection inventoryCount objectCount'.split(' '):
                    del updateItems[item]
                    #updateMsg += 'deleted %s <br/>' % item
                else:
                    updateItems[item] = ''
                    #updateMsg += 'eliminated %s <br/>' % item
            else:
                #updateMsg += 'kept %s, value: %s <br/>' % (item, updateItems[item])
                pass

        try:
            #pass
            updateMsg += updateKeyInfo(fieldset, updateItems, config, form)
            if updateMsg != '':
                msg += '<span style="color:red;">%s</span>' % updateMsg
            numUpdated += 1
        except:
            raise
            #msg += '<span style="color:red;">problem updating</span>'
        #print ('<tr>' + (3 * '<td class="ncell">%s</td>') + '</tr>\n') % (
        #    updateItems['objectNumber'], updateItems['objectCsid'], msg)
        print ('<tr>' + (3 * '<td class="ncell">%s</td>') + '</tr>\n') % ('',updateItems['objectCsid'], msg)
        # print 'place %s' % updateItems['pahmaFieldCollectionPlace']

    print "\n</table>"
    print '<h4>', numUpdated, 'of', row + 1, 'objects had key information updated</h4>'


def doNothing(form, config):
    print '<span style="color:red;">Nothing to do yet! ;-)</span>'


def doUpdateLocations(form, config):

    institution = config.get('info','institution')
    #notlocated = config.get('info','notlocated')
    if institution == 'bampfa':
        notlocated = "urn:cspace:bampfa.cspace.berkeley.edu:locationauthorities:name(location):item:name(x781)'Not Located'"
    else:
        notlocated = "urn:cspace:bampfa.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl23524)'Not located'"
    updateValues = [form.get(i) for i in form if 'r.' in i]

    # if reason is a refname (e.g. bampfa), extract just the displayname
    reason = form.get('reason')
    reason = re.sub(r"^urn:.*'(.*)'", r'\1', reason)

    Now = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    print cswaConstants.getHeader('inventoryResult',institution)

    numUpdated = 0
    for row, object in enumerate(updateValues):

        updateItems = {}
        cells = object.split('|')
        updateItems['objectStatus'] = cells[0]
        updateItems['objectCsid'] = cells[1]
        updateItems['locationRefname'] = cells[2]
        updateItems['subjectCsid'] = '' # cells[3] is actually the csid of the movement record for the current location; the updated value gets inserted later
        updateItems['objectNumber'] = cells[4]
        updateItems['crate'] = cells[5]
        updateItems['inventoryNote'] = form.get('n.' + cells[4]) if form.get('n.' + cells[4]) else ''
        updateItems['locationDate'] = Now
        updateItems['computedSummary'] = updateItems['locationDate'][0:10] + (' (%s)' % reason)

        for i in ('handlerRefName', 'reason'):
            updateItems[i] = form.get(i)

        # ugh...this logic is in fact rather complicated...
        msg = 'location updated.'
        # if we are moving a crate, use the value of the toLocation's refname, which is stored hidden on the form.
        if config.get('info', 'updatetype') == 'movecrate':
            updateItems['locationRefname'] = form.get('toRefname')
            msg = 'crate moved to %s.' % form.get('toLocAndCrate')

        if config.get('info', 'updatetype') in ['moveobject', 'powermove']:
            if updateItems['objectStatus'] == 'do not move':
                msg = "not moved."
            else:
                updateItems['locationRefname'] = form.get('toRefname')
                updateItems['crate'] = form.get('toCrate')
                msg = 'object moved to %s.' % form.get('toLocAndCrate')



        if updateItems['objectStatus'] == 'not found':
            updateItems['locationRefname'] = notlocated
            updateItems['crate'] = ''
            msg = "moved to 'Not Located'."
        try:
            if "not moved" in msg:
                pass
            else:
                updateLocations(updateItems, config, form)
                numUpdated += 1
        except:
            msg = '<span style="color:red;">problem updating</span>'
        print ('<tr>' + (4 * '<td class="ncell">%s</td>') + '</tr>\n') % (
            updateItems['objectNumber'], updateItems['objectStatus'], updateItems['inventoryNote'], msg)\

    print "\n</table>"
    print '<h4>', numUpdated, 'of', row + 1, 'object locations updated</h4>'


def checkObject(places, objectInfo):
    if places == []:
        return True
    elif objectInfo[6] is None:
        return False
    elif objectInfo[6] in places:
        return True
    else:
        return False


def doPackingList(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')

    if form.get('groupbyculture') is not None:
        updateType = 'packinglistbyculture'
    if not validateParameters(form, config): return

    place = form.get("cp.place")
    if place != None and place != '':
        places = cswaGetAuthorityTree.getAuthority('places',  'Placeitem', place,  config.get('connect', 'connect_string'))
        places = [p[0] for p in places]
    else:
        places = []

    #[sys.stderr.write('packing list place term: %s\n' % x) for x in places]
    try:
        locationList = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), MAXLOCATIONS,
                                         config)
    except:
        raise

    rowcount = len(locationList)

    #[sys.stderr.write('packing list locations : %s\n' % x[0]) for x in locationList]

    if rowcount == 0:
        print '<tr><td width="500px"><h2>No locations in this range!</h2></td></tr>'
        return

    print cswaConstants.getHeader(updateType,institution)
    totalobjects = 0
    totallocations = 0
    locations = {}
    for l in locationList:

        try:
            objects = cswaDB.getlocations(l[0], '', 1, config, 'packinglist',institution)
        except:
            raise


        #[sys.stderr.write('packing list objects: %s\n' % x[3]) for x in objects]
        rowcount = len(objects)
        if rowcount == 0:
            if updateType != 'packinglistbyculture':
                locationheader = formatRow({'rowtype': 'subheader', 'data': l}, form, config)
                locations[locationheader] = ['<tr><td colspan="3">No objects found at this location.</td></tr>']
        for r in objects:
            if checkObject(places, r):
                totalobjects += 1
                if updateType == 'packinglistbyculture':
                    temp = copy.deepcopy(r)
                    cgrefname = r[11]
                    parentcount = 0
                    if cgrefname is not None:
                        parents = cswaDB.findparents(cgrefname, config)
                        #[sys.stderr.write('term: %s' % x) for x in parents]
                        if parents is None or len(parents) == 1:
                            subheader = 'zzzNo parent :: %s' % r[7]
                        else:
                            subheader = [term[0] for term in parents]
                            subheader = ' :: '.join(subheader)
                            parentcount = len(parents)
                    else:
                        subheader = 'zzzNo cultural group specified'
                        #sys.stderr.write('%s %s' % (str(r[7]), parentcount))
                    temp[0] = subheader
                    temp[7] = r[0]
                    r = temp
                    locationheader = formatRow({'rowtype': 'subheader', 'data': r}, form, config)
                else:
                    locationheader = formatRow({'rowtype': 'subheader', 'data': r}, form, config)
                if locations.has_key(locationheader):
                    pass
                else:
                    locations[locationheader] = []
                    totallocations += 1

                locations[locationheader].append(formatRow({'rowtype': updateType, 'data': r}, form, config))

    locs = locations.keys()
    locs.sort()
    for header in locs:
        print header.replace('zzz', '')
        print '\n'.join(locations[header])
        print """<tr><td align="center" colspan="6">&nbsp;</tr>"""
    print """<tr><td align="center" colspan="6"><hr><td></tr>"""
    headingtypes = 'cultures' if updateType == 'packinglistbyculture' else 'including crates'
    print """<tr><td align="center" colspan="6">Packing list completed. %s objects, %s locations, %s %s</td></tr>""" % (
        totalobjects, len(locationList), totallocations, headingtypes)
    print "\n</table><hr/>"


def doAuthorityScan(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')
    if not validateParameters(form, config): return

    dead,rare,qualifier = setFilters(form)

    if updateType == 'locreport':
        Taxon = form.get("ut.taxon")
        if Taxon != None:
            Taxa = listAuthorities('taxon', 'TaxonTenant35', Taxon, config, form, 'list')
        else:
            Taxa = []
        tList = [t[0] for t in Taxa]
        column = 1

    elif updateType == 'holdings':
        Place = form.get("px.place")
        if Place != None:
            Places = listAuthorities('places', 'Placeitem', Place, config, form, 'silent')
        else:
            Places = []
        tList = [t[0] for t in Places]
        column = 5

    try:
        objects = cswaDB.getplants('', '', 1, config, 'getalltaxa', qualifier)
    except:
        raise

    rowcount = len(objects)

    if rowcount == 0:
        print '<h2>No plants in this range!</h2>'
        return
        #else:
    #	showTaxon = Taxon
    #   if showTaxon == '' : showTaxon = 'all Taxons in this range'
    #   print '<tr><td width="500px"><h2>%s locations will be listed for %s.</h2></td></tr>' % (rowcount,showTaxon)

    print cswaConstants.getHeader(updateType,institution)
    counts = {}
    statistics = { 'Total items': 'totalobjects',
                   'Accessions': 0,
                   'Unique taxonomic names': 1,
                   'Unique species': 'species',
                   'Unique genera': 'genus'
    }
    for s in statistics.keys():
        counts[s] = cswaConstants.Counter()

    totalobjects = 0
    for t in objects:
        if t[column] in tList:
            if updateType in ['locreport','holdings'] and checkMembership(t[7], rare) and checkMembership(t[8], dead):
                if t[8] == 'true' or t[8] is None:
                    t[3] = "%s [%s]" % (t[13],t[12])
                else:
                    pass
                print formatRow({'rowtype': updateType, 'data': t}, form, config)
                totalobjects += 1
                countStuff(statistics,counts,t,totalobjects)

    #print '\n'.join(accessions)
    print """</table>"""
    #print """<hr/>"""
    #print """<table width="100%">"""
    #print """<tr><td colspan="2"><b>Summary Statistics (experimental and unverified!)</b></tr>"""

    #for s in sorted(statistics.keys()):
    #   print """<tr><th width=300px>%s</th><td>%s</td></tr>""" % (s, len(counts[s]))

    #print """<tr><td align="center">Report completed.</td></tr>"""
    print "\n</table><hr/>"

def countStuff(statistics,counts,data,totalobjects):
    for s in statistics.keys():
        x = counts[s]
        if statistics[s] == 'totalobjects':
            x[totalobjects] += 1
        elif statistics[s] == 'genus':
            parts = data[1].split(' ')
            x[parts[0]] += 1
        elif statistics[s] == 'species':
            parts = data[1].split(' ex ')
            parts = parts[0].split(' var. ')
            x[parts[0]] += 1
        else:
            x[data[statistics[s]]] += 1

def downloadCsv(form, config):
    updateType = config.get('info', 'updateType')
    institution = config.get('info','institution')

    if updateType == 'governmentholdings':
        try:
            query = cswaDB.getDisplayName(config, form.get('agency'))[0]
            hostname = config.get('connect', 'hostname')
            if query == "None":
                print '<h3>Please Select An Agency</h><hr>'
                return
            sites = cswaDB.getSitesByOwner(config, form.get('agency'))
        except:
            raise

        rowcount = len(sites)
        print 'Content-type: application/octet-stream; charset=utf-8'
        print 'Content-Disposition: attachment; filename="Sites By %s.csv"' % query
        print
        writer = csv.writer(sys.stdout, quoting=csv.QUOTE_ALL)
        for s in sites:
                writer.writerow((s[0], s[1], s[2], s[3]))

    else:
        try:
            rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), 500, config)
        except:
            raise

        place = form.get("cp.place")
        if place != None and place != '':
            places = cswaGetAuthorityTree.getAuthority('places',  'Placeitem', place,  config.get('connect', 'connect_string'))
        else:
            places = []

        #rowcount = len(rows)

        filename = 'packinglist%s.csv' % datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S")
        print 'Content-type: application/octet-stream; charset=utf-8'
        print 'Content-Disposition: attachment; filename="%s"' % filename
        print
        writer = csv.writer(sys.stdout, quoting=csv.QUOTE_ALL)
        for r in rows:
            objects = cswaDB.getlocations(r[0], '', 1, config, 'keyinfo', institution)
            #[sys.stderr.write('packing list csv objects: %s\n' % x[3]) for x in objects]
            for o in objects:
                if checkObject(places, o):
                    if institution == 'bampfa':
                        writer.writerow([o[x] for x in [0, 1, 3, 4, 6, 7, 9]])
                    else:
                        writer.writerow([o[x] for x in [0, 2, 3, 4, 5, 6, 7, 9]])
    sys.stdout.flush()
    sys.stdout.close()


def doBarCodes(form, config):
    #updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')

    action = form.get('action')
    if not validateParameters(form, config): return

    if action == "Create Labels for Locations Only":
        print cswaConstants.getHeader('barcodeprintlocations',institution)
    else:
        print cswaConstants.getHeader(updateType,institution)

    totalobjects = 0
    #If the museum number field has input, print by object
    if form.get('ob.objno1') != '':
        try:
            if form.get('ob.objno2'):
                objs = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno2"), 1000, config)
            else:
                objs = cswaDB.getobjlist('range', form.get("ob.objno1"), form.get("ob.objno1"), 1000, config)
        except:
            raise
        if action == 'Create Labels for Objects':
            totalobjects += len(objs)
            o = [o[0:8] + [o[9]] for o in objs]
            labelFilename = writeCommanderFile('objectrange', form.get("printer"), 'objectLabels', 'objects', o, config)
            print '<tr><td>%s</td><td>%s</td><tr><td colspan="4"><i>%s</i></td></tr>' % (
                'objectrange', len(o), labelFilename)
    else:
        try:
            #If no end location, assume single location
            if form.get("lo.location2"):
                rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location2"), 500, config)
            else:
                rows = cswaDB.getloclist('range', form.get("lo.location1"), form.get("lo.location1"), 500, config)
        except:
            raise

        rowcount = len(rows)

        objectsHandled = []
        rows.reverse()
        if action == "Create Labels for Locations Only":
            labelFilename = writeCommanderFile('locations', form.get("printer"), 'locationLabels', 'locations', rows, config)
            print '<tr><td>%s</td><td colspan="4"><i>%s</i></td></tr>' % (len(rows), labelFilename)
            print "\n</table>"
            return
        else:
            for r in rows:
                objects = cswaDB.getlocations(r[0], '', 1, config, updateType,institution)
                for o in objects:
                    if o[3] + o[4] in objectsHandled:
                        objects.remove(o)
                        print '<tr><td>already printed a label for</td><td>%s</td><td>%s</td><td/></tr>' % (o[3], o[4])
                    else:
                        objectsHandled.append(o[3] + o[4])
                totalobjects += len(objects)
                # hack: move the ethnographic file code to the right spot for this app... :-(
                objects = [o[0:8] + [o[9]] for o in objects]
                labelFilename = writeCommanderFile(r[0], form.get("printer"), 'objectLabels', 'objects', objects, config)
                print '<tr><td>%s</td><td>%s</td><tr><td colspan="4"><i>%s</i></td></tr>' % (
                    r[0], len(objects), labelFilename)

    print """<tr><td align="center" colspan="4"><hr/><td></tr>"""
    print """<tr><td align="center" colspan="4">"""
    if totalobjects != 0:
        if form.get('ob.objno1'):
            print "<b>%s object barcode(s) printed." % totalobjects
        else:
            print "<b>%s object(s)</b> found in %s locations." % (totalobjects, rowcount)
    else:
        print '<span class="save">No objects found in this range.</span>'

    print "\n</td></tr></table><hr/>"

def setFilters(form):
    # yes, I know, it does look a bit odd...
    rare = []
    if form.get('rare'):    rare.append('true')
    if form.get('notrare'): rare.append('false')
    dead = []
    qualifier = []
    if 'dora' in form:
        dora = form.get('dora')
        if dora == 'dead':
            dead.append('true')
            qualifier.append('dead')
        elif dora == 'alive':
            dead.append('false')
            qualifier.append('alive')

    qualifier = ' or '.join(qualifier)

    return dead,rare,qualifier

def doAdvancedSearch(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')
    groupby = form.get('groupby')

    if not validateParameters(form, config): return

    dead,rare,qualifier = setFilters(form)

    beds = [form.get(i) for i in form if 'locations.' in i]
    taxa = [form.get(i) for i in form if 'taxon.' in i]
    places = [form.get(i) for i in form if 'places.' in i]

    #taxa: column = 1
    #family: column = 2
    #beds: column = 3
    #place: column = 5

    try:
        objects = cswaDB.getplants('', '', 1, config, 'getalltaxa', qualifier)
    except:
        raise

    print cswaConstants.getHeader(updateType,institution)
    #totalobjects = 0
    accessions = []
    for t in objects:
        if checkMembership(t[1], taxa) and checkMembership(t[3], beds) and checkMembership(t[5],
            places) and checkMembership(t[7], rare) and checkMembership(t[8], dead):
            print formatRow({'rowtype': updateType, 'data': t}, form, config)

    print """</table><table>"""
    print """<tr><td align="center">&nbsp;</tr>"""
    print """<tr><td align="center"><hr></tr>"""
    print """<tr><td align="center">Report completed. %s objects displayed</td></tr>""" % (len(accessions))
    print "\n</table><hr/>"


def checkMembership(item, qlist):
    if item in qlist or qlist == []:
        return True
    else:
        return False


def doBedList(form, config):
    updateactionlabel = config.get('info', 'updateactionlabel')
    updateType = config.get('info', 'updatetype')
    institution = config.get('info','institution')
    groupby = form.get('groupby')

    if not validateParameters(form, config): return

    dead,rare,qualifier = setFilters(form)

    if updateType == 'bedlist':
        rows = [form.get(i) for i in form if 'locations.' in i]
    # currently, the location report does not call this function. but it might...
    elif updateType == 'locreport':
        rows = [form.get(i) for i in form if 'taxon.' in i]

    rowcount = len(rows)
    totalobjects = 0
    if groupby == 'none':
        print cswaConstants.getHeader(updateType + groupby, institution)
    else:
        print '<table>'
    rows.sort()
    for headerid, l in enumerate(rows):

        try:
            objects = cswaDB.getplants(l, '', 1, config, updateType, qualifier)
        except:
            raise

        sys.stderr.write('%-13s:: %s\n' % (updateType, 'l=%s, q=%s, objects: %s' % (l,qualifier,len(objects))))
        if groupby == 'none':
            pass
        else:
            if len(objects) == 0:
                #print '<tr><td colspan="6">No objects found at this location.</td></tr>'
                pass
            else:
                print formatRow({'rowtype': 'subheader', 'data': [l, ]}, form, config)
                print '<tr><td colspan="6">'
                print cswaConstants.getHeader(updateType + groupby if groupby == 'none' else updateType, institution) % headerid

        for r in objects:
            #print "<tr><td>%s<td>%s</tr>" % (len(places),r[6])
            # skip if the accession is not really in this location...
            #print "<tr><td>loc = %s<td>this = %s</tr>" % (l,r[0])
            #if r[4] == '59.1168':
            #    print "<tr><td>"
            #    print r
            #    print "</td></tr>"
            if (checkMembership(r[8],rare) and checkMembership(r[9],dead)) or r[12] == 'Dead':
                # nb: for bedlist, the gardenlocation (r[0]) is not displayed, so the next
                # few lines do not alter the display.
                if checkMembership(r[9],['dead']):
                    r[0] = "%s [%s]" % (r[10],r[12])
                r[0] = "%s = %s :: %s [%s]" % (r[9],r[0],r[10],r[12])
                totalobjects += 1
                print formatRow({'rowtype': updateType, 'data': r}, form, config)

        if groupby == 'none':
            pass
        else:
            if len(objects) == 0:
                pass
            else:
                print '</tbody></table></td></tr>'
                #print """<tr><td align="center" colspan="6">&nbsp;</tr>"""

    if groupby == 'none':
        print "\n</tbody></table>"
    else:
        print '</table>'
    print """<table><tr><td align="center"><hr></tr>"""
    print """<tr><td align="center">Bed List completed. %s objects, %s locations</td></tr>""" % (
        totalobjects, len(rows))
    print "\n</table><hr/>"


def doHierarchyView(form, config):
    query = form.get('authority')
    if query == 'None':
        #hook
        print '<h3>Please select an authority!</h3><hr>'
        return
    res = cswaDB.gethierarchy(query, config)
    print '<div id="tree"></div>\n<script>'
    lookup = {concept.PARENT: concept.PARENT}
    link = ''
    hostname = config.get('connect', 'hostname')
    institution = config.get('info','institution')
    port = ''
    protocol = 'https'
    if query == 'taxonomy':
        link = protocol + '://' + hostname + port + '/collectionspace/ui/' + institution + '/html/taxon.html?csid=%s'
    elif query == 'places':
        link = protocol + '://' + hostname + port + '/collectionspace/ui/' + institution + '/html/place.html?csid=%s'
    else:
        link = protocol + '://' + hostname + port + '/collectionspace/ui/' + institution + '/html/concept.html?csid=%s&vocab=' + query
    for row in res:
        prettyName = row[0].replace('"', "'")
        if len(prettyName) > 0 and prettyName[0] == '@':
            prettyName = '<' + prettyName[1:] + '> '
        prettyName = prettyName + '", url: "' + link % (row[2])
        lookup[row[2]] = prettyName
    print '''var data = ['''
    #print concept.buildJSON(concept.buildConceptDict(res), 0, lookup)
    res = concept.buildJSON(concept.buildConceptDict(res), 0, lookup)
    print re.sub(r'\n    { label: "(.*?)"},', r'''\n    { label: "no parent >> \1"},''', res)
    print '];'
    print """$(function() {
    $('#tree').tree({
        data: data,
        autoOpen: true,
        useContextMenu: false,
        selectable: false
    });
    $('#tree').bind(
    'tree.click',
    function(event) {
        // The clicked node is 'event.node'
        var node = event.node;
        var URL = node.url;
        if (URL) {
            window.open(URL);
        }
    }
);
});</script>"""
    #print "\n</table><hr/>"
    print "\n<hr>"


def doListGovHoldings(form, config):
    query = cswaDB.getDisplayName(config, form.get('agency'))
    if query is None:
        print '<h3>Please Select An Agency: "%s" not found.</h><hr>' % form.get('agency')
        return
    else:
        query = query[0]
    hostname = config.get('connect', 'hostname')
    institution = config.get('info', 'institution')
    protocol = 'https'
    port = ''
    link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/place.html?csid='
    sites = cswaDB.getSitesByOwner(config, form.get('agency'))
    print '<table width="100%">'
    print '<tr><td class="subheader" colspan="4">%s</td></tr>' % query
    print '''<tbody align="center" width=75 style="font-weight:bold">
        <tr><td>Site</td><td>Ownership Note</td><td>Place Note</td></tr></tbody>'''
    for site in sites:
        print "<tr>"
        for field in site:
            if not field:
                field = ''
        print '<td align="left"><a href="' + link + str(cswaDB.getCSID('placeName',site[0], config)[0]) + '&vocab=place">' + site[0] + '</td>'
        print '<td align="left">' + (site[2] or '') + "</td>"
        print '<td align="left">' + (site[3] or '') + "</td>"
        print '</tr><tr><td colspan="3"><hr></td></tr>'
    print "</table>"
    print '<h4>', len(sites), ' sites listed.</h4>'

def writeCommanderFile(location, printerDir, dataType, filenameinfo, data, config):
    # slugify the location
    slug = re.sub('[^\w-]+', '_', location).strip().lower()
    barcodeFile = config.get('files', 'cmdrfmtstring') % (
        dataType, printerDir, slug,
        datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S"), filenameinfo)

    newName = cswaSMBclient.uploadCmdrWatch(barcodeFile, dataType, data, config)

    return newName


def writeLog(updateItems, uri, httpAction, username, config):
    auditFile = config.get('files', 'auditfile')
    updateType = config.get('info', 'updatetype')
    myPid = str(os.getpid())
    # writing of individual log files is now disabled. audit file contains the same data.
    #logFile = config.get('files','logfileprefix') + '.' + datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S") + myPid + '.csv'

    # yes, it is inefficient open the log to write each row, but in the big picture, it's insignificant
    try:
        #csvlogfh = csv.writer(codecs.open(logFile,'a','utf-8'), delimiter="\t")
        #csvlogfh.writerow([updateItems['locationDate'],updateItems['objectNumber'],updateItems['objectStatus'],updateItems['subjectCsid'],updateItems['objectCsid'],updateItems['handlerRefName']])
        csvlogfh = csv.writer(codecs.open(auditFile, 'a', 'utf-8'), delimiter="\t")
        logrec = [ httpAction, datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"), updateType, uri, username ]
        for item in updateItems.keys():
            logrec.append("%s=%s" % (item,updateItems[item]))
        csvlogfh.writerow(logrec)
    except:
        raise
        #print 'writing to log %s failed!' % auditFile
        pass


def writeInfo2log(request, form, config, elapsedtime):
    checkServer = form.get('check')
    location1 = str(form.get("lo.location1"))
    location2 = str(form.get("lo.location2"))
    action = str(form.get("action"))
    serverlabel = config.get('info', 'serverlabel')
    apptitle = config.get('info', 'apptitle')
    updateType = config.get('info', 'updatetype')
    checkServer = form.get('check')
    # override updateType if we are just checking the server
    if checkServer == 'check server':
        updateType = checkServer
    sys.stderr.write('%-13s:: %-18s:: %-6s::%8.2f :: %-15s :: %s :: %s\n' % (updateType, action, request, elapsedtime, serverlabel, location1, location2))
    updateItems = {'app': apptitle, 'server': serverlabel, 'elapsedtime': '%8.2f' % elapsedtime, 'action': action}
    writeLog(updateItems, '', request, '', config)

def uploadFile(actualform, form, config):
    barcodedir = config.get('files', 'barcodedir')
    barcodeprefix = config.get('files', 'barcodeprefix')
    #print form
    # we are using <form enctype="multipart/form-data"...>, so the file contents are now in the FieldStorage.
    # we just need to save it somewhere...
    fileitem = actualform['file']

    # Test if the file was uploaded
    if fileitem.filename:

        # strip leading path from file name to avoid directory traversal attacks
        fn = os.path.basename(fileitem.filename)
        # don't validate uploaded file (faster!)
        #success = processTricoderFile(fileitem, form, config)
        success = True
        if success:
            fileitem.file.seek(0,0)
            open(barcodedir + '/' + barcodeprefix + '.' + fn, 'wb').write(fileitem.file.read())
            os.chmod(barcodedir + '/' + barcodeprefix + '.' + fn, 0666)
            # for now, processing of Tricoder files by this webapp is disabled. john and julian 17 oct 2013
            #numUpdated = processTricoderFile(barcodedir + '/' + barcodeprefix + '.' + fn, form, config)
            message = '%s.%s was uploaded successfully to directory %s!' % (barcodeprefix,fn, barcodedir)
        else:
             message = 'Sorry, your file was rejected for errors.'
    else:
        message = 'No file was chosen to be uploaded. Please choose a file!'

    print "<h3>%s</h3>" % message

def processTricoderFile(barcodefile, form, config):

    id2ref = cswaConstants.tricoderUsers()

    try:
        #print cswaConstants.getHeader('upload','')

        numUpdated = 0

        barcodebuffer = {}
        flag = 0
        while True:
            barcodefile.file.seek(0,0)
            lines = barcodefile.file.readlines()
            for line in lines:
                if line[0] != '"':
                    continue
                data = []
                tempData = line.split('","')
                for datum in tempData:
                    data.append(datum.rstrip())
                data[0] = data[0][1:]
                data[len(data)-1] = data[len(data)-1][:-1]
                #print data
                barcodebuffer[line] = data
            for line in barcodebuffer:
                try:
                    checkData(barcodebuffer[line], line, id2ref, config)
                except Exception, e:
                    print "<span style='color:red'>%s</span><br>" % e
                    flag = 1
            for line in barcodebuffer:
                if flag == 1:
                    #break
                    return False
                #numUpdated += doUploadUpdateLocs(barcodebuffer[line], line, id2ref, form, config)
            break
    except (IOError, AttributeError, LookupError):
        raise
    except Exception, e:
        raise
        #print "<span style='color:red'>%s</span><br>" % e
    #print "\n</table>"
    #return numUpdated
    return True

def checkData(data, line, id2ref, config):
    if data[0] not in ["C", "M", "R"]:
        raise Exception("<span style='color:red'>Error encountered in malformed line '%s':\nMove codes are M, C, or R!</span>" % line)
    if data[1] not in id2ref:
        raise Exception("<span style='color:red'>Error encountered in line '%s':\nHandler ID not recognized!</span>" % line)
    if data[0] == "C":
        try:
            datetime.datetime.strptime(data[2], '%m/%d/%Y %H:%M')
        except ValueError:
            raise Exception("<span style='color:red'>Error encountered in malformed line '%s':\nDate formatting incorrect!</span>" % line)
        if not cswaDB.checkData(config, data[3], "objno")[0]:
            raise Exception("<span style='color:red'>Error encountered in line '%s':\nObject Number not found!</span>" % line)
        if not cswaDB.checkData(config, data[4], "crate")[0]:
            raise Exception("<span style='color:red'>Error encountered in line '%s':\nCrate not found!</span>" % line)
        if not cswaDB.checkData(config, data[5], "location")[0]:
            raise Exception("<span style='color:red'>Error encountered in line '%s':\nLocation not found!</span>" % line)
    elif data[0] == "M":
        if not cswaDB.checkData(config, data[2], "objno")[0]:
            raise Exception("<span style='color:red'>Error encountered in line '%s':\nObject Number not found!</span>" % line)
        if not cswaDB.checkData(config, data[3], "location")[0]:
            raise Exception("<span style='color:red'>Error encountered in line '%s':\nLocation not found!</span>" % line)
        try:
            datetime.datetime.strptime(data[4], '%m/%d/%Y %H:%M')
        except ValueError:
            raise Exception("<span style='color:red'>Error encountered in malformed line '%s':\nDate formatting incorrect!</span>" % line)
    else: #Guaranteed to be "R"
        try:
            datetime.datetime.strptime(data[2], '%m/%d/%Y %H:%M')
        except ValueError:
            raise Exception("<span style='color:red'>Error encountered in malformed line '%s':\nDate formatting incorrect!</span>" % line)
        if not cswaDB.checkData(config, data[3], "crate")[0]:
            raise Exception("<span style='color:red'>Error encountered in line '%s':\nCrate not found!</span>" % line)
        if not cswaDB.checkData(config, data[4], "location")[0]:
            raise Exception("<span style='color:red'>Error encountered in line '%s':\nLocation not found!</span>" % line)



def doUploadUpdateLocs(data, line, id2ref, form, config):
    updateItems = {'crate': '', 'objectNumber': ''}
    if data[0] == "C":
        #Ex: "C","A1234567","07/22/2013 15:54","8-4216","Asian Archaeology Storage Box 0013","Kroeber, 20A, AA  1,  5"
        updateItems['handlerRefName'] = id2ref[data[1]]
        updateItems['locationDate'] = datetime.datetime.strptime(data[2], '%m/%d/%Y %H:%M').strftime("%Y-%m-%dT%H:%M:%SZ")
        updateItems['objectNumber'] = data[3]
        updateItems['crate'] = data[4]
        updateItems['locationRefname'] = cswaDB.getrefname('locations_common', data[5], config)
        updateItems['objectCsid'] = cswaDB.getCSID("objectnumber", data[3], config)[0]
        updateItems['reason'] = form.get('reason')
    elif data[0] == "M":
        #Ex: "M","A1234567","8-4216","Kroeber, 20A, AA  1,  1","07/22/2013 15:54"
        updateItems['handlerRefName'] = id2ref[data[1]]
        updateItems['objectNumber'] = data[2]
        updateItems['locationRefname'] = cswaDB.getrefname('locations_common', data[3], config)
        updateItems['objectCsid'] = cswaDB.getCSID("objectnumber", data[2], config)[0]
        updateItems['locationDate'] = datetime.datetime.strptime(data[4], '%m/%d/%Y %H:%M').strftime("%Y-%m-%dT%H:%M:%SZ")
        updateItems['reason'] = form.get('reason')
    elif data[0] == "R":
        #Ex: "R","A1234567","07/11/2013 17:29","Asian Archaeology Storage Box 0007","Kroeber, 20A, AA  1,  1"
        updateItems['handlerRefName'] = id2ref[data[1]]
        updateItems['locationDate'] = datetime.datetime.strptime(data[2], '%m/%d/%Y %H:%M').strftime("%Y-%m-%dT%H:%M:%SZ")
        updateItems['crate'] = data[3]
        #updateItems['locationRefname'], updateItems['objectCsid'] = cswaDB.getCSID('locations_common', data[4], config)
        updateItems['locationRefname'] = cswaDB.getrefname('locations_common', data[4], config)
        updateItems['objectCsid'] = cswaDB.getCSIDs('crateName', data[3], config)
        updateItems['reason'] = form.get('reason')
    else:
        raise Exception("<span style='color:red'>Error encountered in malformed line '%s':\nMove codes are M, C, or R!</span>" % line)

    updateItems[
        'subjectCsid'] = '' # cells[3] is actually the csid of the movement record for the current location; the updated value gets inserted later
    updateItems['inventoryNote'] = ''
    # if reason is a refname (e.g. bampfa), extract just the displayname
    reason = form.get('reason')
    reason = re.sub(r"^urn:.*'(.*)'", r'\1', reason)
    updateItems['computedSummary'] = updateItems['locationDate'][0:10] + (' (%s)' % reason)

    #print updateItems
    numUpdated = 0
    try:
        if not isinstance(updateItems['objectCsid'], basestring):
            objectCsid = updateItems['objectCsid']
            for csid in objectCsid:
                updateItems['objectNumber'] = cswaDB.getCSIDDetail(config, csid[0], 'objNumber')
                updateItems['objectCsid'] = csid[0]
                updateLocations(updateItems, config)
                numUpdated += 1
                msg = 'Update successful'
                print ('<tr>' + (3 * '<td class="ncell">%s</td>') + '</tr>\n') % (
                    updateItems['objectNumber'], updateItems['crate'], msg)
        else:
            updateLocations(updateItems, config)
            numUpdated += 1
            msg = 'Update successful'
            print ('<tr>' + (3 * '<td class="ncell">%s</td>') + '</tr>\n') % (
                updateItems['objectNumber'], updateItems['inventoryNote'], msg)
    except:
        raise
        #raise Exception('<span style="color:red;">Problem updating line %s </span>' % line)
        #msg = 'Problem updating line %s' % line
        #print ('<tr>' + (3 * '<td class="ncell">%s</td>') + '</tr>\n') % (
        #    updateItems['objectNumber'], updateItems['inventoryNote'], msg)
    return numUpdated

def viewLog(form, config):
    num2ret = int(form.get('num2ret')) if str(form.get('num2ret')).isdigit() else 100

    print '<table>\n'
    print ('<tr>' + (4 * '<th class="ncell">%s</td>') + '</tr>\n') % (
        'locationDate', 'objectNumber', 'objectStatus', 'handler')
    try:
        auditFile = config.get('files', 'auditfile')
        file_handle = open(auditFile)
        file_size = file_handle.tell()
        file_handle.seek(max(file_size - 9 * 1024, 0))

        lastn = file_handle.read().splitlines()[-num2ret:]
        for i in lastn:
            i = i.replace('urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name', '')
            line = ''
            if i[0] == '#': continue
            for l in [i.split('\t')[x] for x in [0, 1, 2, 5]]: line += ('<td>%s</td>' % l)
            #for l in i.split('\t') : line += ('<td>%s</td>' % l)
            print '<tr>' + line + '</tr>'

    except:
        print '<tr><td colspan="4">failed. sorry.</td></tr>'

    print '</table>'


def OldalreadyExists(txt, elements):
    for e in elements:
        if txt == str(e.text):
            #print "    found,skipping: ",txt
            return True
    return False


def IsAlreadyPreferred(txt, elements):
    if elements == []: return False
    if type(elements) == type([]):
        if txt == str(elements[0].text):
            #print "    found,skipping: ",txt
            return True
        return False
    # if we were passed in a single (non-array) Element, just check it..
    if txt == str(elements.text):
        #print "    found,skipping: ",txt
        return True
    return False


def alreadyExists(txt, elements):
    if elements == []: return False
    if type(elements) == type([]):
        for e in elements:
            #element = element[0]
            if txt == str(e.text):
                #print "    found,skipping: ",txt
                return True
        return False
    # if we were passed in a single (non-array) Element, just check it..
    if txt == str(elements.text):
        #print "    found,skipping: ",txt
        return True
    return False


def updateKeyInfo(fieldset, updateItems, config, form):

    message = ''

    realm = config.get('connect', 'realm')
    hostname = config.get('connect', 'hostname')
    username, password = getCreds(form)
    #sys.stderr.write('%-13s:: %s %s\n' % ('creds:',username,password))

    uri = 'collectionobjects'
    getItems = updateItems['objectCsid']

    #Fields vary with fieldsets
    if fieldset == 'keyinfo':
        fieldList = ('pahmaFieldCollectionPlace', 'assocPeople', 'objectName', 'pahmaEthnographicFileCode')
    elif fieldset == 'namedesc':
        fieldList = ('briefDescription', 'objectName')
    elif fieldset == 'registration':
        # nb:  'pahmaAltNumType' is handled with  'pahmaAltNum'
        fieldList = ('objectName', 'pahmaAltNum', 'fieldCollector')
    elif fieldset == 'hsrinfo':
        fieldList = ('objectName', 'pahmaFieldCollectionPlace', 'briefDescription')
    elif fieldset == 'objtypecm':
        fieldList = ('objectName', 'collection', 'responsibleDepartment', 'pahmaFieldCollectionPlace')
    elif fieldset == 'collection':
        fieldList = ('objectName', 'collection')
    elif fieldset == 'placeanddate':
        fieldList = ('pahmaFieldLocVerbatim', 'pahmaFieldCollectionDate')


    # get the XML for this object
    url, content, elapsedtime = getxml(uri, realm, hostname, username, password, getItems)
    root = etree.fromstring(content)
    # add the user's changes to the XML
    for relationType in fieldList:
        #sys.stderr.write('tag1: %s\n' % relationType)
        # this app does not insert empty values into anything!
        if not relationType in updateItems.keys() or updateItems[relationType] == '':
            continue
        listSuffix = 'List'
        extra = ''
        if relationType in ['assocPeople', 'pahmaAltNum', 'pahmaFieldCollectionDate']:
            extra = 'Group'
        elif relationType in ['briefDescription', 'fieldCollector', 'responsibleDepartment']:
            listSuffix = 's'
        elif relationType in ['collection', 'pahmaFieldLocVerbatim']:
            listSuffix = ''
        else:
            pass
            #print ">>> ",'.//'+relationType+extra+'List'
        #sys.stderr.write('tag2: %s\n' % (relationType + extra + listSuffix))
        metadata = root.findall('.//' + relationType + extra + listSuffix)
        try:
            metadata = metadata[0] # there had better be only one!
        except:
            # hmmm ... we didn't find this element in the record. Make a note a carry on!
            # message += 'No "' + relationType + extra + listSuffix + '" element found to update.'
            continue
        #print(etree.tostring(metadata))
        #print ">>> ",relationType,':',updateItems[relationType]
        if relationType in ['assocPeople', 'objectName', 'pahmaAltNum']:
            #group = metadata.findall('.//'+relationType+'Group')
            #sys.stderr.write('  updateItem: ' + relationType + ':: ' + updateItems[relationType] + '\n' )
            Entries = metadata.findall('.//' + relationType)
            if not alreadyExists(updateItems[relationType], Entries):
                newElement = etree.Element(relationType + 'Group')
                leafElement = etree.Element(relationType)
                leafElement.text = updateItems[relationType]
                newElement.append(leafElement)
                if relationType in ['assocPeople', 'pahmaAltNum']:
                    apgType = etree.Element(relationType + 'Type')
                    apgType.text = updateItems[relationType + 'Type'].lower() if relationType == 'pahmaAltNum' else 'made by'
                    #sys.stderr.write(relationType + 'Type:' + updateItems[relationType + 'Type'])
                    newElement.append(apgType)
                if len(Entries) == 1 and Entries[0].text is None:
                    #sys.stderr.write('reusing empty element: %s\n' % Entries[0].tag)
                    #sys.stderr.write('ents : %s\n' % Entries[0].text)
                    #print '<br>before',etree.tostring(metadata).replace('<','&lt;').replace('>','&gt;')
                    for child in metadata:
                        #print '<br>tag: ', child.tag
                        if child.tag == relationType + 'Group':
                            #print '<br> found it! ',child.tag
                            metadata.remove(child)
                    metadata.insert(0,newElement)
                    #print '<br>after',etree.tostring(metadata).replace('<','&lt;').replace('>','&gt;')
                else:
                    metadata.insert(0,newElement)
            else:
                if IsAlreadyPreferred(updateItems[relationType], metadata.findall('.//' + relationType)):
                    continue
                else:
                    # exists, but not preferred. make it the preferred: remove it from where it is, insert it as 1st
                    for child in metadata:
                        if child.tag == relationType + 'Group':
                            checkval = child.find('.//' + relationType)
                            if checkval.text == updateItems[relationType]:
                                savechild = child
                                metadata.remove(child)
                    metadata.insert(0,savechild)
                pass
            # for AltNums, we need to update the AltNumType even if the AltNum hasn't changed
            if relationType == 'pahmaAltNum':
                apgType = metadata.find('.//' + relationType + 'Type')
                apgType.text = updateItems[relationType + 'Type']
                #sys.stderr.write('  updated: pahmaAltNumType to' + updateItems[relationType + 'Type'] + '\n' )
        elif relationType in ['briefDescription', 'fieldCollector', 'responsibleDepartment']:
            Entries = metadata.findall('.//' + relationType)
            #for e in Entries:
                #print '%s, %s<br>' % (e.tag, e.text)
                #sys.stderr.write(' e: %s\n' % e.text)
            if alreadyExists(updateItems[relationType], Entries):
                if IsAlreadyPreferred(updateItems[relationType], Entries):
                    # message += "%s exists as %s, already preferred;" % (updateItems[relationType],relationType)
                    pass
                else:
                    # exists, but not preferred. make it the preferred: remove it from where it is, insert it as 1st
                    for child in Entries:
                        sys.stderr.write(' c: %s\n' % child.tag)
                        if child.text == updateItems[relationType]:
                            new_element = child
                            metadata.remove(child)
                            # message += '%s removed. len = %s<br/>' % (child.text, len(Entries))
                    metadata.insert(0,new_element)
                    message += " %s exists in %s, now preferred.<br/>" % (updateItems[relationType],relationType)
                    #print 'already exists: %s<br>' % updateItems[relationType]
            # check if the existing element is empty; if so, use it, don't add a new element
            else:
                if len(Entries) == 1 and Entries[0].text is None:
                    #message += "removed %s ;<br/>" % (Entries[0].tag)
                    metadata.remove(Entries[0])
                new_element = etree.Element(relationType)
                new_element.text = updateItems[relationType]
                metadata.insert(0,new_element)
                message += "added preferred term %s as %s.<br/>" % (updateItems[relationType],relationType)

        elif relationType in ['pahmaFieldCollectionDate']:
            # we'll be replacing the entire structured date group
            pahmaFieldCollectionDateGroup = metadata.find('.//pahmaFieldCollectionDateGroup')
            newpahmaFieldCollectionDateGroup = etree.Element('pahmaFieldCollectionDateGroup')
            new_element = etree.Element('dateDisplayDate')
            new_element.text = updateItems[relationType]
            newpahmaFieldCollectionDateGroup.insert(0,new_element)
            if pahmaFieldCollectionDateGroup is not None:
                metadata.remove(pahmaFieldCollectionDateGroup)
            metadata.insert(0,newpahmaFieldCollectionDateGroup)

        else:
            # check if value is already present. if so, skip
            if alreadyExists(updateItems[relationType], metadata.findall('.//' + relationType)):
                if IsAlreadyPreferred(updateItems[relationType], metadata.findall('.//' + relationType)):
                    continue
                else:
                    message += "%s: %s already exists. Now duplicated with this as preferred.<br/>" % (relationType,updateItems[relationType])
                    pass
            newElement = etree.Element(relationType)
            newElement.text = updateItems[relationType]
            metadata.insert(0, newElement)
            #print(etree.tostring(metadata, pretty_print=True))
    objectCount = root.find('.//numberOfObjects')
    if 'objectCount' in updateItems:
        if objectCount is None:
            objectCount = etree.Element('numberOfObjects')
            collectionobjects_common = root.find(
                './/{http://collectionspace.org/services/collectionobject}collectionobjects_common')
            collectionobjects_common.insert(0, objectCount)
        objectCount.text = updateItems['objectCount']

    inventoryCount = root.find('.//inventoryCount')
    if 'inventoryCount' in updateItems:
        if inventoryCount is None:
            inventoryCount = etree.Element('inventoryCount')
            collectionobjects_pahma = root.find(
                './/{http://collectionspace.org/services/collectionobject/local/pahma}collectionobjects_pahma')
            collectionobjects_pahma.insert(0, inventoryCount)
        inventoryCount.text = updateItems['inventoryCount']
    #print(etree.tostring(root, pretty_print=True))

    if 'pahmaFieldLocVerbatim' in updateItems:
        pahmaFieldLocVerbatim = root.find('.//pahmaFieldLocVerbatim')
        if pahmaFieldLocVerbatim is None:
            pahmaFieldLocVerbatim = etree.Element('pahmaFieldLocVerbatim')
            pahmaFieldLocVerbatimobjects_common = root.find(
                './/{http://collectionspace.org/services/collectionobject/local/pahma}collectionobjects_pahma')
            pahmaFieldLocVerbatimobjects_common.insert(0, pahmaFieldLocVerbatim)
            message += " %s added as &lt;%s&gt;.<br/>" % (updateItems['pahmaFieldLocVerbatim'], 'pahmaFieldLocVerbatim')
        pahmaFieldLocVerbatim.text = updateItems['pahmaFieldLocVerbatim']

    collection = root.find('.//collection')
    if 'collection' in updateItems:
        if collection is None:
            collection = etree.Element('collection')
            collectionobjects_common = root.find(
                './/{http://collectionspace.org/services/collectionobject}collectionobjects_common')
            collectionobjects_common.insert(0, collection)
            message += " %s added as &lt;%s&gt;.<br/>" % (updateItems['collection'], 'collection')
        collection.text = updateItems['collection']



    uri = 'collectionobjects' + '/' + updateItems['objectCsid']
    payload = '<?xml version="1.0" encoding="UTF-8"?>\n' + etree.tostring(root,encoding='utf-8')
    # update collectionobject..
    #print "<br>pretending to post update to %s to REST API..." % updateItems['objectCsid']
    (url, data, csid, elapsedtime) = postxml('PUT', uri, realm, hostname, username, password, payload)
    writeLog(updateItems, uri, 'PUT', username, config)

    return message

    #print "<h3>Done w update!</h3>"


def updateLocations(updateItems, config, form):
    realm = config.get('connect', 'realm')
    hostname = config.get('connect', 'hostname')
    institution = config.get('info', 'institution')
    username, password = getCreds(form)

    uri = 'movements'

    #print "<br>posting to movements REST API..."
    payload = lmiPayload(updateItems, institution)
    (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
    updateItems['subjectCsid'] = csid

    uri = 'relations'

    #print "<br>posting inv2obj to relations REST API..."
    updateItems['subjectDocumentType'] = 'Movement'
    updateItems['objectDocumentType'] = 'CollectionObject'
    payload = relationsPayload(updateItems)
    (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)

    # reverse the roles
    #print "<br>posting obj2inv to relations REST API..."
    temp = updateItems['objectCsid']
    updateItems['objectCsid'] = updateItems['subjectCsid']
    updateItems['subjectCsid'] = temp
    updateItems['subjectDocumentType'] = 'CollectionObject'
    updateItems['objectDocumentType'] = 'Movement'
    payload = relationsPayload(updateItems)
    (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)

    writeLog(updateItems, uri, 'POST', username, config)

    #print "<h3>Done w update!</h3>"


def formatRow(result, form, config):
    hostname = config.get('connect', 'hostname')
    institution = config.get('info', 'institution')
    port = ''
    protocol = 'https'
    rr = result['data']
    rr = [x if x != None else '' for x in rr]

    if result['rowtype'] == 'subheader':
        #return """<tr><td colspan="4" class="subheader">%s</td><td>%s</td></tr>""" % result['data'][0:1]
        return """<tr><td colspan="7" class="subheader">%s</td></tr>""" % result['data'][0]
    elif result['rowtype'] == 'location':
        return '''<tr><td class="objno"><a href="#" onclick="formSubmit('%s')">%s</a> <span style="color:red;">%s</span></td><td/></tr>''' % (
            result['data'][0], result['data'][0], '')
            #result['data'][0], result['data'][0], result['data'][-1])
    elif result['rowtype'] == 'select':
        rr = result['data']
        boxType = result['boxtype']
        return '''<li class="xspan"><input type="checkbox" name="%s.%s" value="%s" checked> <a href="#" onclick="formSubmit('%s')">%s</a></li>''' % (
            (boxType,) + (rr[0],) * 4)
        #return '''<tr><td class="xspan"><input type="checkbox" name="%s.%s" value="%s" checked> <a href="#" onclick="formSubmit('%s')">%s</a></td><td/></tr>''' % ((boxType,) + (rr[0],) * 4)
    elif result['rowtype'] == 'bedlist':
        groupby = str(form.get("groupby"))
        rare = 'Yes' if rr[8] == 'true' else 'No'
        dead = 'Yes' if rr[9] == 'true' else 'No'
        link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[7]
        if groupby == 'none':
            location = '<td class="zcell">%s</td>' % rr[0]
        else:
            location = ''
            # 3 recordstatus | 4 Accession number | 5 Determination | 6 Family | 7 object csid | 8 rare | 9 dead
        return '''<tr><td class="objno"><a target="cspace" href="%s">%s</a</td><td class="zcell">%s</td><td class="zcell">%s</td><td class="zcell">%s</td><td class="zcell">%s</td>%s</tr>''' % (
            link, rr[4], rr[6], rr[5], rare, dead,location)
    elif result['rowtype'] in ['locreport','holdings','advsearch']:
        rare = 'Yes' if rr[7] == 'true' else 'No'
        dead = 'Yes' if rr[8] == 'true' else 'No'
        link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[6]
        #  0 objectnumber, 1 determination, 2 family, 3 gardenlocation, 4 dataQuality, 5 locality, 6 csid, 7 rare , 8 dead , 9 determination (no author)
        return '''<tr><td class="zcell"><a target="cspace" href="%s">%s</a></td><td class="zcell">%s</td><td class="zcell">%s</td><td class="zcell">%s</td><td class="zcell">%s</td><td class="zcell">%s</td><td class="zcell">%s</td></tr>''' % (
            link, rr[0], rr[1], rr[2], rr[3], rr[5], rare, dead)
    elif result['rowtype'] == 'was.advsearch':
        link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[7]
        # 3 recordstatus | 4 Accession number | 5 Determination | 6 Family | 7 object csid
        #### 3 Accession number | 4 Data quality | 5 Taxonomic name | 6 Family | 7 object csid
        return '''<tr><td class="objno"><a target="cspace" href="%s">%s</a</td><td class="zcell">%s</td><td class="zcell">%s</td><td class="zcell">%s</td></tr>''' % (
            link, rr[4], rr[3], rr[5], rr[6])
    elif result['rowtype'] == 'inventory':
        link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[8]
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objcount 4 | objname 5| movecsid 6 | locrefname 7 | objcsid 8 | objrefname 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        if institution == 'bampfa':
            return """<tr><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td>%s</td><td class="rdo" ><input type="radio" id="sel-move" name="r.%s" value="found|%s|%s|%s|%s|%s" checked></td><td class="rdo" ><input type="radio" id="sel-nomove" name="r.%s" value="not found|%s|%s|%s|%s|%s"/></td><td class="zcell"><input class="xspan" type="text" size="65" name="n.%s"></td></tr>""" % (
            link, rr[3], rr[5], rr[16], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14],
            rr[3])
        else:
            return """<tr><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td class="rdo" ><input type="radio" id="sel-move" name="r.%s" value="found|%s|%s|%s|%s|%s" checked></td><td class="rdo" ><input type="radio" id="sel-nomove" name="r.%s" value="not found|%s|%s|%s|%s|%s"/></td><td class="zcell"><input class="xspan" type="text" size="65" name="n.%s"></td></tr>""" % (
            link, rr[3], rr[5], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14],
            rr[3])
    elif result['rowtype'] == 'powermove':
        link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[8]
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objcount 4 | objname 5| movecsid 6 | locrefname 7 | objcsid 8 | objrefname 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        if institution == 'bampfa':
            return """<tr><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td>%s</td><td class="rdo" ><input type="radio" id="sel-move" name="r.%s" value="found|%s|%s|%s|%s|%s"></td><td class="rdo" ><input type="radio" id="sel-nomove" name="r.%s" value="do not move|%s|%s|%s|%s|%s" checked/></td><td class="zcell"><input class="xspan" type="text" size="65" name="n.%s"></td></tr>""" % (
            link, rr[3], rr[5], rr[16], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14],
            rr[3])
        return """<tr><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td class="rdo" ><input type="radio" id="sel-move" name="r.%s" value="move|%s|%s|%s|%s|%s"></td><td class="rdo" ><input type="radio" id="sel-nomove" name="r.%s" value="do not move|%s|%s|%s|%s|%s" checked/></td><td class="zcell"><input class="xspan" type="text" size="65" name="n.%s"></td></tr>""" % (
            link, rr[3], rr[5], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14], rr[3], rr[8], rr[7], rr[6], rr[3], rr[14],
            rr[3])
    elif result['rowtype'] == 'moveobject':
        link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[8]
        # 0 storageLocation | 1 lockey | 2 locdate | 3 objectnumber | 4 objectName | 5 objectCount | 6 fieldcollectionplace | 7 culturalgroup |
        # 8 objectCsid | 9 ethnographicfilecode | 10 fcpRefName | 11 cgRefName | 12 efcRefName | 13 computedcraterefname | 14 computedcrate
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr><td class="rdo" ><input type="checkbox" name="r.%s" value="moved|%s|%s|%s|%s|%s" checked></td><td class="objno"><a target="cspace" href="%s">%s</a></td><td class="objname">%s</td><td class="zcell">%s</td><td class="zcell">%s</td></tr>""" % (
            rr[3], rr[8], rr[1], '', rr[3], rr[13], link, rr[3], rr[4], rr[5], rr[0])
    elif result['rowtype'] == 'keyinfo' or result['rowtype'] == 'objinfo':
        if institution == 'bampfa':
            link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[2]
            link2 = ''
        else:
            link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[8]
            link2 = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/acquisition.html?csid=%s' % rr[24]
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objname 4 | objcount 5| fieldcollectionplace 6 | culturalgroup 7 | objcsid 8 | ethnographicfilecode 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return formatInfoReviewRow(form, link, rr, link2)
    elif result['rowtype'] == 'packinglist':
        if institution == 'bampfa':
            link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[2]
            return """
            <tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname" name="ti.%s">%s</td>
<td class="ncell" name="ar.%s">%s</td>
<td class="ncell" name="me.%s">%s</td>
<td class="ncell" name="di.%s">%s</td>
<td class="ncell" name="cl.%s">%s</td>
</tr>""" % (link, rr[1], rr[2], rr[3], rr[2], rr[4], rr[2], rr[6], rr[2], rr[7], rr[2], rr[9])

        link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[8]
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objname 4 | objcount 5| fieldcollectionplace 6 | culturalgroup 7 | objcsid 8 | ethnographicfilecode 9
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname" name="onm.%s">%s</td>
<td class="xspan" name="ocn.%s">%s</td>
<td class="xspan" name="cp.%s">%s</td>
<td class="xspan" name="cg.%s">%s</td>
<td class="xspan" name="fc.%s">%s</td>
</tr>""" % (link, rr[3], rr[8], rr[4], rr[8], rr[5], rr[8], rr[6], rr[8], rr[7], rr[8], rr[9])

    elif result['rowtype'] == 'packinglistbyculture':
        link = protocol + '://' + hostname + port + '/collectionspace/ui/'+institution+'/html/cataloging.html?csid=%s' % rr[8]
        # loc 0 | lockey 1 | locdate 2 | objnumber 3 | objname 4 | objcount 5| fieldcollectionplace 6 | culturalgroup 7x | objcsid 8 | ethnographicfilecode 9x
        # f/nf | objcsid | locrefname | [loccsid] | objnum
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname" name="onm.%s">%s</td>
<td class="xspan" name="ocn.%s">%s</td>
<td class="xspan">%s</td>
<td class="xspan" name="fc.%s">%s</td>
</tr>""" % (link, rr[3], rr[8], rr[4], rr[8], rr[5], rr[7], rr[8], rr[6])


def formatInfoReviewRow(form, link, rr, link2):
    """[0 Location, 1 Location Key, 2 Timestamp, 3 Museum Number, 4 Name, 5 Count, 6 Collection Place, 7 Culture, 8 csid,
        9 Ethnographic File Code, 10 Place Ref Name, 11 Culture Ref Name, 12 Ethnographic File Code Ref Name, 13 Crate Ref Name,
        14 Computed Crate 15 Description, 16 Collector, 17 Donor, 18 Alt Num, 19 Alt Num Type, 20 Collector Ref Name,
        21 Accession Number, 22 Donor Ref Name, 23 Acquisition ID, 24 Acquisition CSID]"""
    fieldSet = form.get("fieldset")
    if fieldSet == 'namedesc':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname">
<input class="objname" type="text" name="onm.%s" value="%s">
</td>
<td width="0"></td>
<td class="zcell">
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<textarea cols="78" rows="1" name="bdx.%s">%s</textarea></td>
</tr>""" % (link, cgi.escape(rr[3], True), rr[8], cgi.escape(rr[4], True), rr[8], cgi.escape(rr[3], True), rr[8], rr[8],
            rr[8], cgi.escape(rr[15], True))
    elif fieldSet == 'registration':
        altnumtypes, selected = cswaConstants.getAltNumTypes(form, rr[8], rr[19])
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname">
<input class="objname" type="text" name="onm.%s" value="%s">
</td>
<td class="zcell">
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<input class="xspan" type="text" size="13" name="anm.%s" value="%s"></td>
<td class="zcell">%s</td>
<td class="zcell"><input class="xspan" type="text" size="26" name="pc.%s" value="%s"></td>
<td class="zcell"><span style="font-size:8">%s</span></td>
<td class="zcell"><a target="cspace" href="%s">%s</a></td>
</tr>""" % (link, cgi.escape(rr[3], True), rr[8], cgi.escape(rr[4], True), rr[8], cgi.escape(rr[3], True), rr[8], rr[8],
            rr[8], cgi.escape(rr[18], True), altnumtypes, rr[8], cgi.escape(rr[16], True),
            cgi.escape(rr[17], True), link2, cgi.escape(rr[21], True))
    elif fieldSet == 'keyinfo':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname">
<input class="objname" type="text" name="onm.%s" value="%s">
</td>
<td class="veryshortinput">
<input class="veryshortinput" type="text" name="ocn.%s" value="%s">
</td>
<td class="zcell">
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<input class="xspan" type="text" size="26" name="cp.%s" value="%s"></td>
<td class="zcell"><input class="xspan" type="text" size="26" name="cg.%s" value="%s"></td>
<td class="zcell"><input class="xspan" type="text" size="26" name="fc.%s" value="%s"></td>
</tr>""" % (link, cgi.escape(rr[3], True), rr[8], cgi.escape(rr[4], True), rr[8], rr[5], rr[8], cgi.escape(rr[3], True),
            rr[8], rr[8], rr[8], cgi.escape(rr[6], True), rr[8], cgi.escape(rr[7], True), rr[8], cgi.escape(rr[9], True))
    elif fieldSet == 'hsrinfo':
        return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname">
<input class="objname" type="text" name="onm.%s" value="%s">
</td>
<td class="veryshortinput">
<input class="veryshortinput" type="text" name="ocn.%s" value="%s">
</td>
<td class="zcell">
<input type="hidden" name="oox.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<input class="xspan" type="text" size="20" name="ctn.%s" value="%s"></td>
<td class="zcell"><input class="xspan" type="text" size="26" name="cp.%s" value="%s"></td>
<td class="zcell"><textarea cols="60" rows="1" name="bdx.%s">%s</textarea></td>
</tr>""" % (link, cgi.escape(rr[3], True), rr[8], cgi.escape(rr[4], True), rr[8], rr[5], rr[8], cgi.escape(rr[3], True),
            rr[8], rr[8], rr[8], cgi.escape(rr[25], True), rr[8], cgi.escape(rr[6], True), rr[8], cgi.escape(rr[15], True))
    elif fieldSet == 'objtypecm':
        objtypes, selected = cswaConstants.getObjType(form, rr[8], rr[26])
        collmans, selected = cswaConstants.getCollMan(form, rr[8], rr[27])
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
%s</td>
<td>%s</td>
<td><input class="xspan" type="text" size="26" name="cp.%s" value="%s"></td>
<td><input type="checkbox"></td>
</tr>""" % (link, cgi.escape(rr[3], True), rr[8], cgi.escape(rr[4], True), rr[8], rr[5], rr[8], cgi.escape(rr[3], True),
                  rr[8], rr[8], objtypes, collmans, rr[8], cgi.escape(rr[6], True))
    elif fieldSet == 'collection':
                return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<td class="objname">
<input type="hidden" name="onm.%s" value="">
%s
</td>
<input type="hidden" name="clnx.%s" value="%s">
<input type="hidden" name="csid.%s" value="%s">
<td><input class="xspan" type="text" size="40" name="cln.%s" value="%s"></td>
</tr>""" % (link, cgi.escape(rr[1], True), rr[2], cgi.escape(rr[3], True), rr[2], rr[22], rr[2], rr[2], rr[2], cgi.escape(rr[8], True))
    elif fieldSet == 'placeanddate':
                return """<tr>
<td class="objno"><a target="cspace" href="%s">%s</a></td>
<input type="hidden" name="csid.%s" value="%s">
<td class="objname"><input type="hidden" name="onm.%s" value="">%s</td>
<td><input class="xspan" type="text" size="40" name="vfcp.%s" value="%s"></td>
<td><input class="xspan" type="text" size="40" name="cd.%s" value="%s"></td>
</tr>""" % (link, cgi.escape(rr[3], True), rr[8], rr[8], rr[8], cgi.escape(rr[4], True), rr[8], cgi.escape(rr[28], True), rr[8], cgi.escape(rr[29], True))



def formatInfoReviewForm(form):
    fieldSet = form.get("fieldset")

    if fieldSet == 'namedesc':
        return """<tr><th>Object name</th><td class="objname"><input class="objname" type="text"  size="60" name="onm.user"></td>
</tr><tr><th>Brief Description</th><td class="zcell"><textarea cols="78" rows="7" name="bdx.user"></textarea></td>
</tr>"""
    elif fieldSet == 'registration':
        altnumtypes, selected = cswaConstants.getAltNumTypes(form, 'user','')
        return """<tr><th>Object name</th><td class="objname"><input class="objname" type="text"  size="60" name="onm.user"></td>
</tr><tr><th>Alternate Number</th><td class="zcell"><input class="xspan" type="text" size="60" name="anm.user"></td>
</tr><tr><th>Alternate Number Types</th><td class="zcell">%s</td>
</tr><tr><th>Field Collector (person)</th><td class="zcell"><input class="xspan" type="text" size="60" name="pc.user"></td>
</tr>""" % altnumtypes
    elif fieldSet == 'keyinfo':
        return """<tr><th>Object name</th><td class="objname"><input class="objname" type="text"  size="60" name="onm.user"></td>
</tr><tr><th>Count</th><td class="veryshortinput"><input class="veryshortinput" type="text" name="ocn.user"></td>
</tr><tr><th>Field Collection Place</th><td class="zcell"><input class="xspan" type="text" size="60" name="cp.user"></td>
</tr><tr><th>Cultural Group</th><td class="zcell"><input class="xspan" type="text" size="60" name="cg.user"></td>
</tr><tr><th>Ethnographic File Code</th><td class="zcell"><input class="xspan" type="text" size="60" name="fc.user"></td>
</tr>"""
    elif fieldSet == 'hsrinfo':
        return """<tr><th>Object name</th><td class="objname"><input class="objname" type="text" size="60" name="onm.user"></td>
</tr><tr><th>Count</th><td class="veryshortinput"><input class="veryshortinput" type="text" name="ocn.user"></td>
</tr><tr><th>Count Note</th><td class="zcell"><input class="xspan" type="text" size="25" name="ctn.user"></td>
</tr><tr><th>Field Collection Place</th><td class="zcell"><input class="xspan" type="text" size="50" name="cp.user"></td>
</tr><tr><th>Brief Description</th><td class="zcell"><textarea cols="60" rows="4" name="bdx.user"></textarea></td>
</tr>"""
    elif fieldSet == 'objtypecm':
        objtypes, selected = cswaConstants.getObjType(form, 'user', '')
        collmans, selected = cswaConstants.getCollMan(form, 'user', '')

        return """<tr><th>Object name</th><td class="objname"><input class="objname" type="text" size="60" name="onm.user"></td>
</tr><tr><th>Count</th><td class="veryshortinput"><input class="veryshortinput" type="text" name="ocn.user"></td>
</tr><tr><th>Object Type</th><td class="zcell">%s</td>
</tr><tr><th>Collection Manager</th><td class="zcell">%s</td>
</tr><tr><th>Field Collection Place</th><td><input class="xspan" type="text" size="60" name="cp.user"></td>
</tr>""" % (objtypes, collmans)
    elif fieldSet == 'collection':
        return """<tr><th>Object name</th><td class="objname"><input class="objname" type="text" size="60" name="onm.user"></td>
</tr><tr><th>Collection</th><td><input class="xspan" type="text" size="60" name="cn.user"></td>
</tr>"""
    elif fieldSet == 'placeanddate':
        return """<tr><th>Object name</th>
        <td class="objname"><input class="objname" type="text" size="60" name="onm.user"></td>
</tr>
<tr><th>FCP verbatim</th>
<td><input class="xspan" type="text" size="60" name="vfcp.user"></td>
</tr>"<tr><th>Collection Date</th>
<td><input class="xspan" type="text" size="60" name="cd.user"></td>
</tr>"""


def formatError(cspaceObject):
    return '<tr><th colspan="2" class="leftjust">%s</th><td></td><td>None found.</td></tr>\n' % (cspaceObject)


def getxml(uri, realm, hostname, username, password, getItems):
    # port and protocol need to find their ways into the config files...
    port = ''
    protocol = 'https'
    server = protocol + "://" + hostname + port
    passman = urllib2.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passman)
    opener = urllib2.build_opener(authhandler)
    urllib2.install_opener(opener)
    if getItems == None:
        url = "%s/cspace-services/%s" % (server, uri)
    else:
        url = "%s/cspace-services/%s/%s" % (server, uri, getItems)
    #sys.stderr.write('url %s' % url )
    elapsedtime = 0.0

    try:
        elapsedtime = time.time()
        f = urllib2.urlopen(url)
        data = f.read()
        elapsedtime = time.time() - elapsedtime
    except urllib2.HTTPError, e:
        sys.stderr.write('The server couldn\'t fulfill the request.')
        sys.stderr.write( 'Error code: %s' % e.code)
        raise
    except urllib2.URLError, e:
        sys.stderr.write('We failed to reach a server.')
        sys.stderr.write( 'Reason: %s' % e.reason)
        raise
    else:
        return (url, data, elapsedtime)

        #data = "\n<h3>%s :: %s</h3>" % e


def postxml(requestType, uri, realm, hostname, username, password, payload):
    port = ''
    protocol = 'https'
    server = protocol + "://" + hostname + port
    passman = urllib2.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passman)
    opener = urllib2.build_opener(authhandler)
    urllib2.install_opener(opener)
    url = "%s/cspace-services/%s" % (server, uri)
    elapsedtime = 0.0

    elapsedtime = time.time()
    request = urllib2.Request(url, payload, {'Content-Type': 'application/xml'})
    # default method for urllib2 with payload is POST
    if requestType == 'PUT': request.get_method = lambda: 'PUT'
    try:
        f = urllib2.urlopen(request)
    except urllib2.URLError, e:
        if hasattr(e, 'reason'):
            sys.stderr.write('We failed to reach a server.\n')
            sys.stderr.write('Reason: ' + str(e.reason) + '\n')
        if hasattr(e, 'code'):
            sys.stderr.write('The server couldn\'t fulfill the request.\n')
            sys.stderr.write('Error code: ' + str(e.code) + '\n')
        if True:
            #print 'Error in POSTing!'
            sys.stderr.write("Error in POSTing!\n")
            sys.stderr.write(url)
            sys.stderr.write(payload)
            raise

    data = f.read()
    info = f.info()
    # if a POST, the Location element contains the new CSID
    if info.getheader('Location'):
        csid = re.search(uri + '/(.*)', info.getheader('Location'))
        csid = csid.group(1)
    else:
        csid = ''
    elapsedtime = time.time() - elapsedtime
    return (url, data, csid, elapsedtime)


def printCollectionStats(form, config):
    writeInfo2log('start', form, config, 0.0)
    logo = config.get('info', 'logo')
    schemacolor1 = config.get('info', 'schemacolor1')
    serverlabel = config.get('info', 'serverlabel')
    serverlabelcolor = config.get('info', 'serverlabelcolor')
    apptitle = config.get('info', 'apptitle')
    updateType = config.get('info', 'updatetype')

    divsize = '''<div id="sidiv" style="position:relative; width:1300px; height:750px; color:black; ">'''

    print '''Content-type: text/html; charset=utf-8


<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>''' + apptitle + ' : ' + serverlabel + '''</title>
<style type="text/css">
body { margin:10px 10px 0px 10px; font-family: Arial, Helvetica, sans-serif; }
table { width: 100%; }
td { cell-padding: 3px; }
.stattitle { font-weight: normal; text-align:right; }
.statvalue { font-weight: bold; text-align:left; }
.statvaluecenter { font-weight: bold; text-align:center; }
th { text-align: left ;color: #666666; font-size: 16px; font-weight: bold; cell-padding: 3px;}
h1 { font-size:32px; float:left; padding:10px; margin:0px; border-bottom: none; }
h2 { font-size:12px; float:left; color:white; background:black; }
p { padding:10px 10px 10px 10px; }

button { font-size: 150%; width:85px; text-align: center; text-transform: uppercase;}

.statsection { font-size:21px; font-weight:bold; border-bottom: thin dotted #aaaaaa; color: #660000; }
.statheader { font-weight: bold; text-align:center; font-size:medium; }
.stattitle { font-weight: bold; text-align:right; font-size:small; }
.statvalue { font-weight: normal; text-align:left; font-size:x-small; }
.statbignumber { font-weight: bold; text-align:center; font-size:medium; }
.statnumber { font-weight: bold; text-align:right; font-size:x-small; }
.statpct { font-weight: normal; text-align:left; font-size:x-small; }
.objtitle { font-size:28px; float:left; padding:2px; margin:0px; border-bottom: thin dotted #aaaaaa; color: #000000; }
.objsubtitle { font-size:28px; float:left; padding:2px; margin:0px; border-bottom: thin dotted #aaaaaa; font-style: italic; color: #999999; }
.notentered { font-style: italic; color: #999999; }
.askjohn { font-style: italic; color: #009999; }

.addtoquery { font-style: italic; color: #aa0000; }
.cell { line-height: 1.0; text-indent: 2px; color: #666666; font-size: 16px;}
.enumerate { background-color: green; font-size:20px; color: #FFFFFF; font-weight:bold; vertical-align: middle; text-align: center; }
img#logo { float:left; height:50px; padding:10px 10px 10px 10px;}
.locations { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 18px; }
.ncell { line-height: 1.0; cell-padding: 2px; font-size: 16px;}
.error {color:red;}
.rdo { text-align: center; }
.save { background-color: BurlyWood; font-size:20px; color: #000000; font-weight:bold; vertical-align: middle; text-align: center; }
.dashboardcell { width:265px; height:190px;
-moz-border-radius:9px; border-radius:9px;
border:2px solid black; position:relative;
display:inline-block; margin:13px; padding:5px;
cursor: pointer;}
.dashboardpane { position:fixed; top:1px;
left:1px; right:1px; bottom:1px;overflow:hidden;
-moz-border-radius:9px; border-radius:9px;
border:2px solid black; text-align:left;
background:#CCC; display:none; padding:8px;
background:rgba(0,0,0,0.2);}
#overlay { position:fixed; top:0; left:0; width:100%; height:100%; background:#000;
opacity:0.5; filter:alpha(opacity=50); display:none; overflow:hidden}
.content {border-radius:7px; background:#fff;
padding:20px; height:93%; overflow-y:auto;overflow-x:auto; position:relative;}
.table{display:none; background:#fff; float:left; margin-left:305px;}
.selection{height:150px; width:300px; float:left; background:#fff; position:fixed; cursor:pointer;}
.charts{float:left; background:#fff; margin-left:305px;}
.time{float:left; display:none; background:#fff; margin-left:305px;}
.close{float:right; margin-top:-12.5px; margin-right:-5.5px; z-index:25; position:absolute; right:0px}
.charts-menu-vertical { max-height: 300px; overflow-y: auto; z-index: 15;}
.useHead{ font-weight: bold; }
.useBody{ display: inline-block; padding-left: 3em; }
</style>

<style type="text/css">
  /*<![CDATA[*/
    @import "../css/jquery-ui-1.8.22.custom.css";
  /*]]>*/
  </style>
<script type="text/javascript" src="../js/jquery-1.7.2.min.js"></script>
<script type="text/javascript" src="../js/jquery-ui-1.8.22.custom.min.js"></script>
<script type="text/javascript" src="../js/provision.js"></script>
<script type="text/javascript" src="https://www.google.com/jsapi"></script>
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
    document.forms['ucbwebapp'].submit();
}
</script>
</head>
<body>
<form id="ucbwebapp" enctype="multipart/form-data" method="post">
<table width="100%" cellpadding="0" cellspacing="0" border="0">
  <tbody><tr><td width="3%">&nbsp;</td><td align="center">''' + divsize + '''
    <table>
    <tbody>
      <tr>
	<td style="width: 400px; color: #000000; font-size: 32px; font-weight: bold;">''' + apptitle + '''</td>
        <td><span style="color:''' + serverlabelcolor + ''';">''' + serverlabel + '''</td>
	<th style="text-align:right;"><img height="60px" src="''' + logo + '''"></th>
      </tr>
      <tr><td colspan="3"></td></tr>
      <tr>
	<td colspan="3">
	<table>
	  <tr><td><table>
	</table>
        </td><td style="width:3%"/>
	<td style="width:120px;text-align:center;"></td>
      </tr>
      </table></td></tr>
      <tr><td colspan="3"><div id="status"><hr/></div></td></tr>
    </tbody>
    </table>'''

    dbsource = 'pahma.cspace.berkeley.edu'

    print '''<div>
    <span style="font-size:20px;"><b>%s</b> Total Museum Numbers &bull; <b>%s</b> Total Objects &bull; <b>%s</b> Total Pieces</span><br>
    <span style="font-size:16px; font-style:italic">All counts accurate as of %s</span><br></div>
''' % (cswaCollectionUtils.getTopStats(dbsource, config))

    print '''<div id='overlay'></div>
<div style="text-align:center;">'''

    statcodes = ['total', 'cont', 'obj', 'cat', 'acc', 'efc', 'coll', 'iot']
    longform = {'total': 'Total Counts', 'cont': 'Continent', 'obj': 'Object Type', 'cult': 'Culture', 'cat': 'Catalog',
                'don': 'Donor','acc': 'Accession Status', 'efc': 'Ethnographic Use Code', 'coll': 'Collection Manager', 'iot': 'Objects Photographed'}

    for code in statcodes:
        if code == 'total':
            print '''
    <div class="dashboardcell" id="%s">
        <img src="../images/%s.png" alt="%s" id="%simg">
    </div>''' % (code, code, longform[code], code)
        else:
            print '''
    <div class="dashboardcell" id="%s">
        <img src="../images/%s.png" alt="By %s" id="%simg">
    </div>''' % (code, code, longform[code], code)
    print '</div>'

    imgsrc = "../images/x.png"
    for code in statcodes:
        print '''<div class="dashboardpane" id="%spane">
    <div class="close" id="%sclose">
        <img src="%s" alt="close">
    </div>
    <div class="content">''' % (code, code, imgsrc)
        cswaCollectionUtils.makeSelection(code)
        cswaCollectionUtils.makeChart(code, longform[code], dbsource, config)
        cswaCollectionUtils.makeTable(code, longform[code], dbsource, config)
        cswaCollectionUtils.makeTime(code, dbsource, config)
        print '''
    </div>
</div>'''
    print "</div>"




def starthtml(form, config):
    writeInfo2log('start', form, config, 0.0)
    logo = config.get('info', 'logo')
    schemacolor1 = config.get('info', 'schemacolor1')
    serverlabel = config.get('info', 'serverlabel')
    serverlabelcolor = config.get('info', 'serverlabelcolor')
    apptitle = config.get('info', 'apptitle')
    updateType = config.get('info', 'updatetype')
    institution = config.get('info', 'institution')
    username = form.get('csusername')
    password = form.get('cspassword')
    msg = ''
    if form.get('checkauth') is not None:
        if authenticateUser(username, password, form, config):
            pass
        else:
            username = None
            msg = 'login again!'
    elif form.get('inputusername') is not None:
        username = form.get('inputusername')
        password = form.get('inputpassword')
        if authenticateUser(username, password, form, config):
            pass
        else:
            username = None
            msg = 'not valid!'
    if username is None:
        username = ''
        password = ''
        updateType = 'login'

    #num2ret   = str(form.get('num2ret')) if str(form.get('num2ret')).isdigit() else '50'

    button = '''<input id="actionbutton" class="save" type="submit" value="Search" name="action">'''

    #appOptions = '''<select onchange="this.form.submit()">
    #    ...
    #    </select>'''

    programName = os.path.basename(__file__).replace('Utils', 'Main') + '?webapp=' # yes, this is fragile!
    #appOptions = getAppOptions('pahma')

    appOptions = '''
    <a target="%s" class="littlebutton" onclick="$('#ucbwebapp').attr('action', '%s').submit(); return false;">%s</a>
    &nbsp;&nbsp;&nbsp;&nbsp;
    <a target="help" href="%s">Help</a>
    ''' % ('switchapp', programName + 'switchapp', 'switch app',
           'https://webapps.cspace.berkeley.edu/webappmanual/%s-webappmanual.html' % institution)

    #groupbyelement = '''
    #      <th><span class="cell">group by:</span></th>
    #      <th>
    #      <span class="cell">none </span><input type="radio" name="groupby" value="none">
    #      <span class="cell">name </span><input type="radio" name="groupby" value="determination">
    #      <span class="cell">family </span><input type="radio" name="groupby" value="family">
    #      <span class="cell">location </span><input type="radio" name="groupby" value="gardenlocation">
    #      </th>'''
    #groupby   = str(form.get("groupby")) if form.get("groupby") else 'gardenlocation'

    # temporary, until the other groupings and sortings work...
    groupbyelement = '''
          <th><span class="cell">group by: </span></th>
          <th><span class="cell">none </span><input type="radio" name="groupby" value="none">
          <span class="cell">location </span><input type="radio" name="groupby" value="location"></th>
          '''

    groupby = str(form.get("groupby")) if form.get("groupby") else 'location'
    groupbyelement = groupbyelement.replace(('value="%s"' % groupby), ('checked value="%s"' % groupby))

    deadoralive = '''
      <th><span class="cell">filters: </span></th>
      <th><span class="cell">rare </span>
	  <input id="rare" class="cell" type="checkbox" name="rare" value="rare" class="xspan">
          <span class="cell">not rare </span>
	  <input id="notrare" class="cell" type="checkbox" name="notrare" value="notrare" class="xspan">
          ||
	  <span class="cell">alive </span>
	  <input id="alive" class="cell" type="radio" name="dora" value="alive" class="xspan">
	  <span class="cell">dead </span>
	  <input id="dead" class="cell" type="radio" name="dora" value="dead" class="xspan"></th>'''

    for v in ['rare', 'notrare']:
        if form.get(v):
            deadoralive = deadoralive.replace('value="%s"' % v, 'checked value="%s"' % v)
        else:
            deadoralive = deadoralive.replace('checked value="%s"' % v, 'value="%s"' % v)
    if 'dora' in form:
        deadoralive = deadoralive.replace('value="%s"' % form['dora'], 'checked value="%s"' % form['dora'])
    else:
        deadoralive = deadoralive.replace('value="%s"' % 'alive', 'checked value="%s"' % 'alive')

    location1 = str(form.get("lo.location1")) if form.get("lo.location1") else ''
    location2 = str(form.get("lo.location2")) if form.get("lo.location2") else ''
    otherfields = '''
	  <tr><th><span class="cell">start location:</span></th>
	  <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
          <th><span class="cell">end location:</span></th>
          <th><input id="lo.location2" class="cell" type="text" size="40" name="lo.location2" value="''' + location2 + '''" class="xspan"></th></tr>
    '''

    if updateType == 'login':
        button = '''<input id="actionbutton" class="save" type="submit" value="Login" name="action">'''
        otherfields = '''
	    <tr><th><span class="cell">username:</span></th>
	    <th><input id="inputusername" class="cell" type="text" size="40" name="inputusername" class="xspan"></th></tr>
        <tr><th><span class="cell">password:</span></th>
        <th><input id="inputpassword" class="cell" type="password" size="40" name="inputpassword" class="xspan"></th>
        </tr>
    '''

    elif updateType == 'keyinfo':
        location1 = str(form.get("lo.location1")) if form.get("lo.location1") else ''
        location2 = str(form.get("lo.location2")) if form.get("lo.location2") else ''
        fieldset, selected = cswaConstants.getFieldset(form, institution)

        otherfields = '''
	    <tr><th><span class="cell">start location:</span></th>
	    <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
        <th><span class="cell">end location:</span></th>
        <th><input id="lo.location2" class="cell" type="text" size="40" name="lo.location2" value="''' + location2 + '''" class="xspan"></th>
        <th><th><span class="cell">set:</span></th><th>''' + fieldset + '''</th></tr>
    '''
        otherfields += '''
        <tr></tr>'''

    elif updateType == 'bulkedit' or updateType == 'objinfo':
        objno1 = str(form.get("ob.objno1")) if form.get("ob.objno1") else ''
        objno2 = str(form.get("ob.objno2")) if form.get("ob.objno2") else ''
        fieldset, selected = cswaConstants.getFieldset(form, institution)

        otherfields = '''
        <tr><th><span class="cell">start object no:</span></th>
        <th><input id="ob.objno1" class="cell" type="text" size="32" name="ob.objno1" value="''' + objno1 + '''" class="xspan"></th>
        <th><span class="cell">end object no:</span></th>
        <th><input id="ob.objno2" class="cell" type="text" size="32" name="ob.objno2" value="''' + objno2 + '''" class="xspan"></th>
        <th><th><span class="cell">set:</span></th><th>''' + fieldset + '''</th></tr>
        '''
        otherfields += '''
        <tr></tr>'''

    elif updateType == 'objdetails':
        objectnumber = str(form.get('ob.objectnumber')) if form.get('ob.objectnumber') else ''
        otherfields = '''
	  <tr><td><span class="cell">Museum Number:</span></td>
	  <td><input id="ob.objectnumber" class="cell" type="text" size="40" name="ob.objectnumber" value="''' + objectnumber + '''" class="xspan"></td></tr>'''

    elif updateType == 'moveobject':
        objno1 = str(form.get("ob.objno1")) if form.get("ob.objno1") else ''
        objno2 = str(form.get("ob.objno2")) if form.get("ob.objno2") else ''
        crate = str(form.get("lo.crate")) if form.get("lo.crate") else ''
        handlers, selected = cswaConstants.getHandlers(form, institution)
        reasons, selected = cswaConstants.getReasons(form, institution)

        otherfields = '''
        <tr><th><span class="cell">start object no:</span></th>
        <th><input id="ob.objno1" class="cell" type="text" size="40" name="ob.objno1" value="''' + objno1 + '''" class="xspan"></th>
        <th><span class="cell">end object no:</span></th>
        <th><input id="ob.objno2" class="cell" type="text" size="40" name="ob.objno2" value="''' + objno2 + '''" class="xspan"></th></tr>
        '''
        otherfields += '''
	  <tr><th><span class="cell">destination:</span></th>
	  <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
          <th><span class="cell">reason:</span></th><th>''' + reasons + '''</th>
          <tr><th><span class="cell">crate:</span></th>
          <th><input id="lo.crate" class="cell" type="text" size="40" name="lo.crate" value="''' + crate + '''" class="xspan"></th>
          <th><span class="cell">handler:</span></th><th>''' + handlers + '''</th></tr>
        '''

    elif updateType == 'movecrate':
        crate = str(form.get("lo.crate")) if form.get("lo.crate") else ''
        otherfields = '''
	  <tr><th><span class="cell">from:</span></th>
	  <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
          <th><span class="cell">to:</span></th>
          <th><input id="lo.location2" class="cell" type="text" size="40" name="lo.location2" value="''' + location2 + '''" class="xspan"></th></tr>
          <tr><th><span class="cell">crate:</span></th>
          <th><input id="lo.crate" class="cell" type="text" size="40" name="lo.crate" value="''' + crate + '''" class="xspan"></th></tr>
    '''

        handlers, selected = cswaConstants.getHandlers(form, institution)
        reasons, selected = cswaConstants.getReasons(form, institution)
        otherfields += '''
          <tr><th><span class="cell">reason:</span></th><th>''' + reasons + '''</th>
          <th><span class="cell">handler:</span></th><th>''' + handlers + '''</th></tr>'''


    elif updateType == 'powermove':
        location1 = str(form.get("lo.location1")) if form.get("lo.location1") else ''
        location2 = str(form.get("lo.location2")) if form.get("lo.location2") else ''
        crate1 = str(form.get("lo.crate1")) if form.get("lo.crate1") else ''
        crate2 = str(form.get("lo.crate2")) if form.get("lo.crate2") else ''
        otherfields = '''
	      <tr><th><span class="cell">from location:</span></th>
	      <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
	      <th><span class="cell">to location:</span></th>
          <th><input id="lo.location2" class="cell" type="text" size="40" name="lo.location2" value="''' + location2 + '''" class="xspan"></th></tr>
          <tr><th><span class="cell">crate (optional):</span></th>
          <th><input id="lo.crate1" class="cell" type="text" size="40" name="lo.crate1" value="''' + crate1 + '''" class="xspan"></th>
          <th><span class="cell">crate (optional):</span></th>
          <th><input id="lo.crate2" class="cell" type="text" size="40" name="lo.crate2" value="''' + crate2 + '''" class="xspan"></th></tr>
    '''

        handlers, selected = cswaConstants.getHandlers(form, institution)
        reasons, selected = cswaConstants.getReasons(form, institution)
        otherfields += '''
          <tr><th><span class="cell">reason:</span></th><th>''' + reasons + '''</th>
          <th><span class="cell">handler:</span></th><th>''' + handlers + '''</th></tr>'''

    elif updateType == 'bedlist':
        location1 = str(form.get("lo.location1")) if form.get("lo.location1") else ''
        otherfields = '''
	  <tr>
          <th><span rowspan="2" class="cell">bed:</span></th>
	  <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
          <th><table><tr>''' + groupbyelement + '''</tr><tr>''' + deadoralive + '''</tr></table></th>
          </tr>'''

    elif updateType == 'locreport':
        taxName = str(form.get('ut.taxon')) if form.get('ut.taxon') else ''
        otherfields = '''
	  <tr><th><span class="cell">taxonomic name:</span></th>
	  <th><input id="ut.taxon" class="cell" type="text" size="40" name="ut.taxon" value="''' + taxName + '''" class="xspan"></th>
          ''' + deadoralive + '''</tr> '''

    elif updateType == 'holdings':
        place = str(form.get('px.place')) if form.get('px.place') else ''
        otherfields = '''
	  <tr><th><span class="cell">collection place:</span></th>
	  <th><input id="px.place" class="cell" type="text" size="40" name="px.place" value="''' + place + '''" class="xspan"></th>
          ''' + deadoralive + '''</tr> '''

    elif updateType == 'advsearch':
        location1 = str(form.get("lo.location1")) if form.get("lo.location1") else ''
        taxName = str(form.get('ut.taxon')) if form.get('ut.taxon') else ''
        objectnumber = str(form.get('ob.objectnumber')) if form.get('ob.objectnumber') else ''
        place = str(form.get('px.place')) if form.get('px.place') else ''
        concept = str(form.get('cx.concept')) if form.get('cx.concept') else ''

        otherfields = '''
	  <tr><th><span class="cell">taxonomic name:</span></th>
	  <th><input id="ut.taxon" class="cell" type="text" size="40" name="ut.taxon" value="''' + taxName + '''" class="xspan"></th>
          ''' + groupbyelement + '''</tr>
	  <tr>
          <th><span class="cell">bed:</span></th>
	  <th><input id="lo.location1" class="cell" type="text" size="40" name="lo.location1" value="''' + location1 + '''" class="xspan"></th>
          ''' + deadoralive + '''</tr>
	  <tr><th><span class="cell">collection place:</span></th>
	  <th><input id="px.place" class="cell" type="text" size="40" name="px.place" value="''' + place + '''" class="xspan"></th>
	  </tr>
          '''

        saveForNow = '''
	  <tr><th><span class="cell">concept:</span></th>
	  <th><input id="cx.concept" class="cell" type="text" size="40" name="cx.concept" value="''' + concept + '''" class="xspan"></th></tr>'''

    elif updateType == 'search':
        objectnumber = str(form.get('ob.objectnumber')) if form.get('ob.objectnumber') else ''
        place = str(form.get('cp.place')) if form.get('cp.place') else ''
        concept = str(form.get('co.concept')) if form.get('co.concept') else ''
        otherfields += '''
	  <tr><th><span class="cell">museum number:</span></th>
	  <th><input id="ob.objectnumber" class="cell" type="text" size="40" name="ob.objectnumber" value="''' + objectnumber + '''" class="xspan"></th></tr>
	  <tr><th><span class="cell">concept:</span></th>
	  <th><input id="co.concept" class="cell" type="text" size="40" name="co.concept" value="''' + concept + '''" class="xspan"></th></tr>
	  <tr><th><span class="cell">collection place:</span></th>
	  <th><input id="cp.place" class="cell" type="text" size="40" name="cp.place" value="''' + place + '''" class="xspan"></th></tr>'''

    elif updateType == 'barcodeprint':
        printers, selected, printerlist = cswaConstants.getPrinters(form)
        objno1 = str(form.get("ob.objno1")) if form.get("ob.objno1") else ''
        objno2 = str(form.get("ob.objno2")) if form.get("ob.objno2") else ''
        otherfields += '''
<tr><th><span class="cell">first museum number:</span></th>
<th><input id="ob.objno1" class="cell" type="text" size="40" name="ob.objno1" value="''' + objno1 + '''" class="xspan"></th>
<th><span class="cell">last museum number:</span></th>
<th><input id="ob.objno2" class="cell" type="text" size="40" name="ob.objno2" value="''' + objno2 + '''" class="xspan"></tr>
<tr><th><span class="cell">printer cluster:</span></th><th>''' + printers + '''</th>
<th colspan="4"><i>NB: object number range supersedes location range, if entered.</i></th>
</tr>'''

    elif updateType == 'inventory':
        handlers, selected = cswaConstants.getHandlers(form, institution)
        reasons, selected = cswaConstants.getReasons(form, institution)
        otherfields += '''
          <tr><th><span class="cell">reason:</span></th><th>''' + reasons + '''</th>
          <th><span class="cell">handler:</span></th><th>''' + handlers + '''</th></tr>'''

    elif updateType == 'packinglist' or updateType == 'packinglistbyculture':
        if institution == 'bampfa':
            pass
        else:
            place = str(form.get('cp.place')) if form.get('cp.place') else ''
            otherfields += '''
	  <tr><th><span class="cell">collection place:</span></th>
	  <th><input id="cp.place" class="cell" type="text" size="40" name="cp.place" value="''' + place + '''" class="xspan"></th>'''
            otherfields += '''
          <th><span class="cell">group by culture </span></th>
	  <th><input id="groupbyculture" class="cell" type="checkbox" name="groupbyculture" value="groupbyculture" class="xspan"></th</tr>'''
            if form.get('groupbyculture'): otherfields = otherfields.replace('value="groupbyculture"',
                                                                         'checked value="groupbyculture"')

    elif updateType == 'upload':
        reasons, selected = cswaConstants.getReasons(form, institution)
        
        button = '''<input id="actionbutton" class="save" type="submit" value="Upload" name="action">'''
        otherfields = '''<tr><th><span class="cell">file:</span></th><th><input type="file" name="file"></th><th/></tr>
<th><span class="cell">reason:</span></th><th>''' + reasons + '''</th>'''
        
    elif updateType == 'hierarchyviewer':
        hierarchies, selected = cswaConstants.getHierarchies(form)
        button = '''<input id="actionbutton" class="save" type="submit" value="View Hierarchy" name="action">'''
        otherfields = '''<tr><th><span class="cell">Authority:</span></th><th>''' + hierarchies + '''</th></tr>'''

    elif updateType == 'governmentholdings':
        agencies, selected = cswaConstants.getAgencies(form)
        button = '''<input id="actionbutton" class="save" type="submit" value="View Holdings" name="action">'''
        otherfields = '''<tr><th><span class="cell">Agency:</span></th><th>''' + agencies + '''</th>'''
        otherfields += """<td><input type="submit" class="save" value="%s" name="action"></td>""" % 'Download as CSV'

    elif updateType == 'intake':

        fielddescription = cswaConstants.getIntakeFields('intake')

        button = '''
            <input id="actionbutton" class="save" type="submit" value="Start Intake" name="action">
            <input id="actionbutton" class="save" type="submit" value="View Intakes" name="action"><br/>
            '''

        otherfields = '<tr>'
        for i,box in enumerate(fielddescription):
            if i % 3 == 0:
                otherfields += "</tr><tr>"
            if box[4] == 'fixed':
                otherfields += '''
                <th><span class="cell">%s</span></th>
                <th><input id="%s" class="cell" type="hidden" size="%s" name="%s" value="%s" class="xspan">
                <b>%s</b></th>
                ''' % (box[0],box[2],box[1],box[2],box[3],box[3])
            else:
                otherfields += '''
                 <th><span class="cell">%s</span></th>
                <th><input id="%s" class="cell" type="%s" size="%s" name="%s" value="%s" class="xspan"></th>
                ''' % (box[0],box[2],box[4],box[1],box[2],box[3])
        otherfields += '</tr>'

    else:
        otherfields = '''
          <th><span class="cell">problem:</span></th>
          <th>internal error: updateType not specified</th></tr>
          <tr><th/><th/><th/><th/></tr>'''

    return '''Content-type: text/html; charset=utf-8

    
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>''' + apptitle + ' : ' + serverlabel + '''</title>''' + cswaConstants.getStyle(schemacolor1) + '''
<style type="text/css">
/*<![CDATA[*/
@import "../css/jquery-ui-1.8.22.custom.css";
@import "../css/blue/style.css";
@import "../css/jqtree.css";
/*]]>*/
</style>
<script type="text/javascript" src="../js/jquery-1.7.2.min.js"></script>
<script type="text/javascript" src="../js/jquery-ui-1.8.22.custom.min.js"></script>
<script type="text/javascript" src="../js/jquery.tablesorter.js"></script>
<script src="../js/tree.jquery.js"></script>
<style>
.ui-autocomplete-loading { background: white url('../images/ui-anim_basic_16x16.gif') right center no-repeat; }
</style>
<script type="text/javascript">
function formSubmit(location)
{
    console.log(location);
    document.getElementById('lo.location1').value = location
    document.getElementById('lo.location2').value = location
    //document.getElementById('actionbutton').value = "Next"
    document.forms['ucbwebapp'].submit();
}
</script>
</head>
<body>
<form id="ucbwebapp" enctype="multipart/form-data" method="post">
<table cellpadding="0" cellspacing="0" border="0">
  <tbody><tr><td width="2%">&nbsp;</td>
  <td>
    <table>
    <tbody>
      <tr>
	<td class="cell" style="width: 500px; color: #000000; font-size: 32px; font-weight: bold;">''' + apptitle + '''</td>
    <td style="min-width: 100px; text-align: right; padding-right: 10px;">
    <table>
    <tr><td style="text-align: right;"><span class="tiny">server</span></td></tr>
    <tr><td style="text-align: right;"><span class="tiny">user</span></td></tr>
    <tr><td style="text-align: right;"><span class="tiny"><a class="littlebutton" href="''' + programName + '''">logout</a></span><span class="tiny"> or</span></td></tr>
    </table>
    </td>
    <td style="min-width: 140px; text-align: left; padding-right: 10px;">
    <table>
    <tr><td><span class="tiny" style="color:''' + serverlabelcolor + ''';">''' + serverlabel + '''</span></td></tr>
    <tr><td style="height: 18px;"><span class="tiny">''' + username + '''</span><span class="error">''' + msg + '''</span></td></tr>
    <tr><td><span class="tiny">''' + appOptions + '''</span><span class="tiny">&nbsp;</span></td></tr>
    </table>
    </td>
    <td><div style="width:80px; ";" id="appstatus"><img height="60px" src="../images/timer-animated.gif"></div></td>
	<th style="text-align:right;"><img height="60px" src="''' + logo + '''"></th>
      </tr>
      <tr><td colspan="5"><hr/></td></tr>
      <tr><th colspan="5">
    <table width="100%">
        <tr>
        <th>
        <table>
	  ''' + otherfields + '''
        </table>
        </th>
        <td style="width:80px;text-align:center;">''' + button + '''</td>
        </tr>
    </table>
    </th></tr>
    <tr><td colspan="5"><div id="status"><hr/></div></td></tr>
    </tbody>
    </table>
    <input type="hidden" name="csusername" value="''' + username + '''">
    <input type="hidden" name="cspassword" value="''' + password + '''">
'''


def endhtml(form, config, elapsedtime):
    writeInfo2log('end', form, config, elapsedtime)
    #user = form.get('user')
    count = form.get('count')
    connect_string = config.get('connect', 'connect_string')
    focusSnippet = ""
    addenda = '''

d = document.getElementById("appstatus");
d.innerHTML = '&nbsp;';

});'''
    # for object details, clear out the input field on focus, for everything else, just focus
    if config.get('info', 'updatetype') == 'objdetails':
        focusSnippet = '''$('input:text:first').focus().val("");'''
    else:
        focusSnippet = '''$('input:text:first').focus();'''
    if config.get('info', 'updatetype') == 'collectionstats':
        addenda = '''$(".dashboardcell").click(function() {
		var paneid = $(this).attr('id') + 'pane';
		$('#' + paneid).show();
		$('#overlay').show();
	});
	$(".close").click(function() {
		var closeid = $(this).attr('id').replace("close","pane");
		$('#' + closeid).hide();
		$('#overlay').hide();
	});
	$(".selimg").click(function() {
		var showid = $(this).attr('id').replace("sel","");
		if(showid.indexOf("close") != -1) {
                    var closeid = showid.replace("close","pane");
                    $('#' + closeid).hide();
                    $('#overlay').hide();
		} else if(showid.indexOf("chart") != -1) {
			$('#' + showid.replace("chart", "table")).hide();
			$('#' + showid.replace("chart", "time")).hide();
			if (document.getElementById(showid).style.display == 'none'){
				$('#' + showid).show(0)
			} //else {
				//$('#' + showid).hide();
			//}
		} else if(showid.indexOf("table") != -1) {
			$('#' + showid.replace("table", "chart")).hide();
			$('#' + showid.replace("table", "time")).hide();
			$('#' + showid).show(0)		
		} else if(showid.indexOf("time") != -1) {
			$('#' + showid.replace("time", "chart")).hide();
			$('#' + showid.replace("time", "table")).hide();
			$('#' + showid).show(0)
		}
	});
});'''
    return '''
  <table>
    <tbody>
    <tr>
      <td width="80px"><input id="checkbutton" class="cell" type="submit" value="check server" name="check"></td>
      <td width="180px" class="xspan">''' + time.strftime("%b %d %Y %H:%M:%S", time.localtime()) + '''</td>
      <td width="120px" class="cell">elapsed time: </td>
      <td class="xspan">''' + ('%8.2f' % elapsedtime) + ''' seconds</td>
      <td style="text-align: right;" class="cell">powered by </td>
      <td style="text-align: right;width: 170;" class="cell"><img src="../images/header-logo-cspace.png" height="30px"></td>
    </tr>
    </tbody>
  </table>
</td><td width="2%">&nbsp;</td></tr>
</tbody></table>
</form>
<script>
$(function () {
       $("[name^=select-]").click(function (event) {
           var selected = this.checked;
           var mySet    = $(this).attr("name");
           mySet = mySet.replace('select-','');
           // console.log(mySet);
           // Iterate each checkbox
           $("[name^=" + mySet + "]").each(function () { this.checked = selected; });
       });
    });

$(document).on('click', '#check-move', function() {
    if ($('#check-move').is(':checked')) {
        $('input[id="sel-move"]').each(function () { this.checked = true; });
    } else {
        $('input[id="sel-nomove"]').each(function () { this.checked = true; });
    }
});


$(document).ready(function () {

''' + focusSnippet + '''

$(function() {
  $('[id^="sortTable"]').map(function() {
        // console.log(this);
        $(this).tablesorter({debug: true})
     });
  });
  
$('[name]').map(function() {
    var elementID = $(this).attr('name');
    if (elementID.indexOf('.') == 2) {
        // console.log(elementID);
        $(this).autocomplete({
            source: function(request, response) {
                $.ajax({
                    url: "../cgi-bin/autosuggest.py?webapp=''' + urllib2.quote(form['webapp']) + '''",
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

''' + addenda + '''
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
    payload = payload % (f['objectCsid'], f['objectDocumentType'], f['subjectCsid'], f['subjectDocumentType'])
    return payload


def lmiPayload(f,institution):
    if institution == 'bampfa':
        payload = """<?xml version="1.0" encoding="UTF-8"?>
<document name="movements">
<ns2:movements_common xmlns:ns2="http://collectionspace.org/services/movement" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<reasonForMove>%s</reasonForMove>
<currentLocation>%s</currentLocation>
<locationDate>%s</locationDate>
<movementNote>%s</movementNote>
<movementContact>%s</movementContact>
</ns2:movements_common>
<ns2:movements_bampfa xmlns:ns2="http://collectionspace.org/services/movement/domain/anthropology" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<computedSummary>%s</computedSummary>
<crate>%s</crate>
</ns2:movements_bampfa>
</document>
"""

        payload = payload % (
            f['reason'], f['locationRefname'], f['locationDate'], f['inventoryNote'], f['handlerRefName'],
            f['computedSummary'], f['crate'])

    else:
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
        payload = payload % (
            f['reason'], f['locationRefname'], f['locationDate'], f['inventoryNote'], f['computedSummary'], f['crate'],
            f['handlerRefName'])

    return payload


if __name__ == "__main__":

    # to test this module on the command line you have to pass in two cgi values:
    # $ python cswaUtils.py "lo.location1=Hearst Gym, 30, L 12,  2&lo.location2=Hearst Gym, 30, L 12,  7"
    # $ python cswaUtils.py "lo.location1=X&lo.location2=Y"

    # this will load the config file and attempt to update some records in server identified
    # in that config file!


    updateItems = {}

    if True:

        print "starting keyinfo update"

        form = {'webapp': 'pahma_Keyinfo_Dev', 'action': 'Update Object Information',
                'fieldset': 'placeanddate',
                'csusername': 'import@pahma.cspace.berkeley.edu',
                'cspassword': 'lash428!puck',
                #'fieldset': 'registration',
                'onm.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'Cradle',
                'oox.70d40782-6d11-4346-bb9b-2f85f1e00e91': '1-1',
                'csid.70d40782-6d11-4346-bb9b-2f85f1e00e91': '70d40782-6d11-4346-bb9b-2f85f1e00e91',
                'vfcp.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'yyy',
                'cd.70d40782-6d11-4346-bb9b-2f85f1e00e91': '11/3/15',
        }

        config = getConfig(form)

        doUpdateKeyinfo(form, config)


    if False:

        print "starting keyinfo update"

        form = {'webapp': 'pahma_Keyinfo_Dev', 'action': 'Update Object Information',
                'fieldset': 'namedesc',
                'csusername': 'import@pahma.cspace.berkeley.edu',
                'cspassword': 'lash428!puck',
                #'fieldset': 'registration',
                'onm.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'Cradle',
                'oox.70d40782-6d11-4346-bb9b-2f85f1e00e91': '1-1',
                'csid.70d40782-6d11-4346-bb9b-2f85f1e00e91': '70d40782-6d11-4346-bb9b-2f85f1e00e91',
                'bdx.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'brief description 999 888 777',
                'anm.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'xxx',
                'ant.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'xxx',
                'pc.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'Dr. Philip Mills Jones',
        }

        config = getConfig(form)

        doUpdateKeyinfo(form, config)


    if False:

        form = {'webapp': 'keyinfoDev', 'action': 'Update Object Information',
                'fieldset': 'namedesc',
                #'fieldset': 'registration',
                'onm.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'Cradle',
                'oox.70d40782-6d11-4346-bb9b-2f85f1e00e91': '1-1',
                'csid.70d40782-6d11-4346-bb9b-2f85f1e00e91': '70d40782-6d11-4346-bb9b-2f85f1e00e91',
                'bdx.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'brief description 999 888 777',
                'anm.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'xxx',
                'ant.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'xxx',
                'pc.70d40782-6d11-4346-bb9b-2f85f1e00e91': 'Dr. Philip Mills Jones',
        }

        form = {'webapp': 'ucbgLocationReportDev', 'dora': 'alive'}
        config = getConfig(form)

        starthtml(form, config)
        print setFilters(form)

        doUpdateKeyinfo(form, config)

        #sys.exit()

    if False:

        form = {'webapp': 'bamInventoryDev'}
        config = getConfig(form)

        realm = config.get('connect', 'realm')
        hostname = config.get('connect', 'hostname')
        username = 'import@bampfa.cspace.berkeley.edu'
        password = 'bjeScwj2'
        institution = config.get('info', 'institution')

        #print relationsPayload(f)

        updateItems = {'objectStatus': 'found',
              'subjectCsid': '41568668-00a7-439b-8a09-8525578e5df4',
              'objectCsid': '41568668-00a7-439b-8a09-8525578e5df4',
              'inventoryNote': 'inventory note',
              'crate': '',
              'handlerRefName': "JW",
              'reason': "urn:cspace:bampfa.cspace.berkeley.edu:vocabularies:name(movereason):item:name(movereason002)'Exhibition'",
              'computedSummary': 'systematic inventory test',
              'locationRefname': "urn:cspace:bampfa.cspace.berkeley.edu:locationauthorities:name(location):item:name(x793)'Print Storage, Bin 02 Lower'",
              'locationDate': '2014-10-23T05:45:30Z',
              'objectNumber': '9-12689'}

        #updateLocations(f2,config)
        #print "updateLocations succeeded..."
        #sys.exit(0)

        uri = 'movements'

        print "<br>posting to movements REST API..."
        payload = lmiPayload(updateItems,institution)
        print payload
        #sys.exit(0)

        (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
        updateItems['subjectCsid'] = csid
        print 'got csid', csid, '. elapsedtime', elapsedtime
        print "movements REST API post succeeded..."

        uri = 'relations'

        print "<br>posting inv2obj to relations REST API..."
        updateItems['subjectDocumentType'] = 'Movement'
        updateItems['objectDocumentType'] = 'CollectionObject'
        payload = relationsPayload(updateItems)
        (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
        print 'got csid', csid, '. elapsedtime', elapsedtime
        print "relations REST API post succeeded..."

        # reverse the roles
        print "<br>posting obj2inv to relations REST API..."
        temp = updateItems['objectCsid']
        updateItems['objectCsid'] = updateItems['subjectCsid']
        updateItems['subjectCsid'] = temp
        updateItems['subjectDocumentType'] = 'CollectionObject'
        updateItems['objectDocumentType'] = 'Movement'
        payload = relationsPayload(updateItems)
        (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
        print 'got csid', csid, '. elapsedtime', elapsedtime
        print "relations REST API post succeeded..."

        print "<h3>Done w update!</h3>"

        #sys.exit()


    if False:

        form = {'webapp': 'bamInventoryDev'}
        config = getConfig(form)

        realm = config.get('connect', 'realm')
        hostname = config.get('connect', 'hostname')
        username = config.get('connect', 'username')
        password = config.get('connect', 'password')
        institution = config.get('info', 'institution')

        #print lmiPayload(f)
        #print relationsPayload(f)

        f2 = {'objectStatus': 'found',
              'subjectCsid': '',
              'inventoryNote': '',
              'crate': "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(crate):item:name(cr2113)'Faunal Box 421'",
              'handlerRefName': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(999)'Michael T. Black'",
              'objectCsid': '35d1e048-e803-4e19-81de-ac1079f9bf47',
              'reason': 'Inventory',
              'computedSummary': 'systematic inventory test',
              'locationRefname': "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl12158)'Kroeber, 20A, AA 1, 2'",
              'locationDate': '2012-07-24T05:45:30Z',
              'objectNumber': '9-12689'}

        #updateLocations(f2,config)
        #print "updateLocations succeeded..."
        #sys.exit(0)

        uri = 'movements'

        print "<br>posting to movements REST API..."
        payload = lmiPayload(updateItems)
        (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
        updateItems['subjectCsid'] = csid
        print 'got csid', csid, '. elapsedtime', elapsedtime
        print "movements REST API post succeeded..."

        uri = 'relations'

        print "<br>posting inv2obj to relations REST API..."
        updateItems['subjectDocumentType'] = 'Movement'
        updateItems['objectDocumentType'] = 'CollectionObject'
        payload = relationsPayload(updateItems)
        (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
        print 'got csid', csid, '. elapsedtime', elapsedtime
        print "relations REST API post succeeded..."

        # reverse the roles
        print "<br>posting obj2inv to relations REST API..."
        temp = updateItems['objectCsid']
        updateItems['objectCsid'] = updateItems['subjectCsid']
        updateItems['subjectCsid'] = temp
        updateItems['subjectDocumentType'] = 'CollectionObject'
        updateItems['objectDocumentType'] = 'Movement'
        payload = relationsPayload(updateItems)
        (url, data, csid, elapsedtime) = postxml('POST', uri, realm, hostname, username, password, payload)
        print 'got csid', csid, '. elapsedtime', elapsedtime
        print "relations REST API post succeeded..."

        print "<h3>Done w update!</h3>"

        #sys.exit()

    if False:

        print cswaDB.getplants('Velleia rosea', '', 1, config, 'locreport', 'dead')
        #sys.exit()

        endhtml(form, config, 0.0)


    if False:
        #print "starting packing list"
        #doPackingList(form,config)
        #sys.exit()
        print '\nlocations\n'
        for loc in cswaDB.getloclist('range', '1001, Green House 1', '1003, Tropical House', 1000, config):
            print loc

        print '\nlocations\n'
        for loc in cswaDB.getloclist('set', 'Kroeber, 20A, W B', '', 10, config):
            print loc

        print '\nlocations\n'
        for loc in cswaDB.getloclist('set', 'Kroeber, 20A, CC  4', '', 3, config):
            print loc

        print '\nobjects\n'
        rows = cswaDB.getlocations('Kroeber, 20A, CC  4', '', 3, config, 'keyinfo','pahma')
        for r in rows:
            print r

        #urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl31520)'Regatta, A150, RiveTier 1, B'
        f = {'objectCsid': '242e9ee7-983a-49e9-b3b5-7b49dd403aa2',
             'subjectCsid': '250d75dc-c704-4b3b-abaa',
             'locationRefname': "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(sl284)'Kroeber, 20Mez, 53 D'",
             'locationDate': '2000-01-01T00:00:00Z',
             'computedSummary': 'systematic inventory test',
             'inventoryNote': 'this is a test inventory note',
             'objectDocumentType': 'CollectionObject',
             'subjectDocumentType': 'Movement',
             'reason': 'Inventory',
             'handlerRefName': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7412)'Madeleine W. Fang'"

        }

        #print lmiPayload(f)
        #print relationsPayload(f)

        form = {'webapp': 'barcodeprintDev', 'ob.objectnumber': '1-504', 'action': 'Create Labels for Objects'}

        config = getConfig(form)

        print doBarCodes(form, config)
        #sys.exit()
