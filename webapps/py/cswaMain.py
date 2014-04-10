#!/usr/bin/env /usr/bin/python

import sys
import time
import cgi
import traceback
import cgitb; cgitb.enable()  # for troubleshooting
from cswaUtils import *
from cswaObjDetails import *

reload(sys)
sys.setdefaultencoding('utf-8')

# NB we convert FieldStorage to a dict, but we need the actual form for barcode upload...
actualform = cgi.FieldStorage()
form       = cgiFieldStorageToDict(actualform)

action      = form.get('action')
checkServer = form.get('check')

config  = getConfig(form)
# we don't do anything with debug now, but it is a comfort to have
debug = form.get("debug")

# bail if we don't know which webapp to be...(i.e. no config object passed in from cswaMain)
if config == False:
    print selectWebapp(form)
    sys.exit(0)

updateType  = config.get('info','updatetype')

# if action has not been set, this is the first time through, and we need to set defaults. (only 1 right now!)
if not action or action == 'Login':
    form['alive'] = 'checked'
    
# if location2 was not specified, default it to location1
if str(form.get('lo.location2')) == '':
    form['lo.location2'] = form.get('lo.location1')

# same for objects
if str(form.get('ob.objno2')) == '':
    form['ob.objno2'] = form.get('ob.objno1')

if (updateType == 'packinglist' or updateType == 'governmentholdings') and action == 'Download as CSV':  
    downloadCsv(form,config)
    sys.exit(0)
elif updateType == 'collectionstats':
    printCollectionStats(form, config)
else:    
    print starthtml(form,config)

elapsedtime = time.time()
try:
    sys.stdout.flush()

    if checkServer == 'check server':
        print serverCheck(form,config)
    else:
        if action == "Enumerate Objects":
            doEnumerateObjects(form,config)
        elif action == "Create Labels for Locations Only":
            doBarCodes(form,config)
        elif action == config.get('info','updateactionlabel'):
            if   updateType == 'packinglist':  doPackingList(form,config)
            elif updateType == 'movecrate':    doUpdateLocations(form,config)
            elif updateType == 'barcodeprint': doBarCodes(form,config)
            elif updateType == 'inventory':    doUpdateLocations(form,config)
            elif updateType == 'moveobject':   doUpdateLocations(form,config)
            elif updateType == 'objinfo':      doUpdateKeyinfo(form,config)
            elif updateType == 'keyinfo':      doUpdateKeyinfo(form,config)
            elif updateType == 'bulkedit':     doBulkEdit(form,config)
            elif updateType == 'bedlist':      doBedList(form,config)
            elif updateType == 'advsearch':    doAdvancedSearch(form,config)
            elif updateType == 'upload':       uploadFile(actualform,form,config)
            elif updateType == 'governmentholdings': doListGovHoldings(form, config)
            elif updateType == 'editrel':      doRelationsEdit(form,config)
            elif updateType == 'makegroup':    makeGroup(form,config)
            elif action == "Recent Activity":
                viewLog(form,config)
    ##    # special case: if only one location in range, jump to enumerate
    ##    elif form.getvalue("lo.location1") != '' and str(form.getvalue("lo.location1")) == str(form.getvalue("lo.location2")) :
    ##        if updateType in ['keyinfo', 'inventory']:
    ##            doEnumerateObjects(form,config)
    ##        elif updateType == 'movecrate':
    ##            doCheckMove(form,config)
    ##        else:
    ##            doLocationSearch(form,config,'nolist')
        elif action == "Search":
            if   updateType == 'packinglist':  doLocationSearch(form,config,'nolist')
            elif updateType == 'movecrate':    doCheckMove(form,config)
            elif updateType == 'barcodeprint':
                if form.get('ob.objno1'):
                    doOjectRangeSearch(form, config)
                else:
                    doLocationSearch(form, config, 'nolist')
            elif updateType == 'bedlist':      doComplexSearch(form,config,'select')
            elif updateType == 'bulkedit':     doBulkEditForm(form,config,'nolist')
            elif updateType == 'holdings':     doAuthorityScan(form,config)
            elif updateType == 'locreport':    doAuthorityScan(form,config)
            elif updateType == 'advsearch':    doComplexSearch(form,config,'select')
            elif updateType == 'inventory':    doLocationSearch(form,config,'list')
            elif updateType == 'keyinfo':      doLocationSearch(form,config,'list')
            elif updateType == 'objinfo':      doObjectSearch(form,config,'list')
            elif updateType == 'moveobject':   doObjectSearch(form,config,'list')
            elif updateType == 'objdetails':   doObjectDetails(form,config)
            elif updateType == 'editrel':      doRelationsSearch(form,config)
            elif updateType == 'makegroup':    doComplexSearch(form,config,'select')

        elif action == "View Hierarchy":
            doHierarchyView(form,config)
        elif action == "View Holdings":
            doListGovHoldings(form,config)
        elif action in ['<<','>>']:
            print "<h3>Sorry not implemented yet! Please try again tomorrow!</h3>"
        else:
            pass
            #print "<h3>Unimplemented action %s!</h3>" % str(action)

except:
    sys.stderr.write("error! %s" % traceback.format_exc())
    print '''<h3><span class="error">Sorry! An error occurred; it has been logged and will be investigated.<br/>
        However, it may take some days before the log is reviewed, so please contact John Lowe jblowe@berkeley.edu directly
        if you have even the <i>slightest</i> concern about getting this issue resolved.
        Also, please record the time and what you were doing when this unfortunate event happened. Screenshots, are helpful, too.
        </span></h3>'''

elapsedtime = time.time() - elapsedtime

print endhtml(form,config,elapsedtime)
