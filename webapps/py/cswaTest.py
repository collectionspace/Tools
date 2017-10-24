from cswaUtils import *

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
