# -*- coding: UTF-8 -*-

import csv

def getStyle(schemacolor1):
    return '''
<style type="text/css">
body { margin:10px 10px 0px 10px; font-family: Arial, Helvetica, sans-serif; }
table { width: 100%; }
td { cell-padding: 3px; }
th { text-align: left ;color: #666666; font-size: 16px; font-weight: bold; cell-padding: 3px;}
h1 { font-size:32px; padding:10px; margin:0px; border-bottom: none; }
h2 { font-size:24px; color:white; background:blue; }
p { padding:10px 10px 10px 10px; }
li { text-align: left; list-style-type: none; }
a { text-decoration: none; }
button { font-size: 150%; width:85px; text-align: center; text-transform: uppercase;}
.cell { line-height: 1.0; text-indent: 2px; color: #666666; font-size: 16px;}
.enumerate { background-color: green; font-size:20px; color: #FFFFFF; font-weight:bold; vertical-align: middle; text-align: center; }
img#logo { float:left; height:50px; padding:10px 10px 10px 10px;}
.authority { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 18px; }
.ncell { line-height: 1.0; cell-padding: 2px; font-size: 16px;}
.objname { font-weight: bold; font-size: 16px; font-style: italic; width:200px; }
.objno { font-weight: bold; font-size: 16px; font-style: italic; width:160px; }
.ui-tabs .ui-tabs-panel { padding: 0px; min-height:120px; }
.rdo { text-align: center; width:60px; }
.error {color:red;}
.save { background-color: BurlyWood; font-size:20px; color: #000000; font-weight:bold; vertical-align: middle; text-align: center; }
.shortinput { font-weight: bold; width:150px; }
.subheader { background-color: ''' + schemacolor1 + '''; color: #FFFFFF; font-size: 24px; font-weight: bold; }
.smallheader { background-color: ''' + schemacolor1 + '''; color: #FFFFFF; font-size: 12px; font-weight: bold; }
.veryshortinput { width:60px; }
.xspan { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 12px; }
th[data-sort]{ cursor:pointer; }
.littlebutton {color: #FFFFFF; background-color: gray; font-size: 11px; padding: 2px;}
.imagecell { padding: 8px ; align: center; }
.rightlabel { text-align: right ; vertical-align: top; padding: 2px 12px 2px 2px; width: 30%; }
.objtitle { font-size:28px; float:left; padding:4px; margin:0px; border-bottom: thin dotted #aaaaaa; color: #000000; }
.objsubtitle { font-size:28px; float:left; padding:2px; margin:0px; border-bottom: thin dotted #aaaaaa; font-style: italic; color: #999999; }
.notentered { font-style: italic; color: #999999; }
</style>
'''

def tricoderUsers():
    #*** Ape prohibited list code to get table ***
    return{'A1732177': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7827)'Michael T. Black'",
              'A1676856': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8700)'Raksmey Mam'",
              'A0951620': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7475)'Leslie Freund'",
              'A1811681': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7652)'Natasha Johnson'",
              'A2346921': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(9090)'Corri MacEwen'",
              'A2055958': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8683)'Alicja Egbert'",
              'A2507976': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8731)'Tya Ates'",
              'A2247942': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(9185)'Alex Levin'",
              'A2346563': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(9034)'Martina Smith'",
              'A1728294': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7420)'Jane L. Williams'",
              'A1881977': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8724)'Allison Lewis'",
              'A2472847': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(RowanGard1342219780674)'Rowan Gard'",
              'A1687900': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7500)'Elizabeth Minor'",
              'A2472958': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(AlexanderJackson1345659630608)'Alexander Jackson'",
              'A2503701': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(GavinLee1349386412719)'Gavin Lee'",
              'A2504029': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(RonMartin1349386396342)'Ron Martin' ",
              'A1148429': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8020)'Paolo Pellegatti'",
              'A0904690': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7267)'Victoria Bradshaw'",
              'A2525169': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(GrainneHebeler1354748670308)'Grainne Hebeler'",
              '20271721': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(KatieFleming1353023599564)'KatieFleming'",
              'A2266779': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(KatieFleming1353023599564)'KatieFleming'",
              'A2204739': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(PaigeWalker1351201763000)'PaigeWalker'",
              'A0701434': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7248)'Madeleine W. Fang'",
              'A2532024': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(LindaWaterfield1358535276741)'LindaWaterfield'",
              'A2581770': "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(JonOligmueller1372192617217)'JonOligmueller'"}


def infoHeaders(fieldSet):
    if fieldSet == 'keyinfo':
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
    elif fieldSet == 'namedesc':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th></th>
      <th style="text-align:center">Brief Description</th>
      <th>P?</th>
    </tr>"""
    elif fieldSet == 'registration':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Alt Num</th>
      <th>Alt Num Type</th>
      <th>Field Collector</th>
      <th>Donor</th>
      <th>Accession</th>
      <th>P?</th>
    </tr>"""
    elif fieldSet == 'hsrinfo':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Count</th>
      <th>Count Note</th>
      <th>Field Collection Place</th>
      <th style="text-align:center">Brief Description</th>
      <th>P?</th>
    </tr>"""
    else:
        return "<table><tr>DEBUG</tr>"

def getProhibitedLocations(appconfig):
    #fileName = appconfig.get('files','prohibitedLocations.csv')
    fileName = 'prohibitedLocations.csv'
    locList = []
    try:
        with open(fileName, 'rb') as csvfile:
            csvreader = csv.reader(csvfile, delimiter="\t")
            for row in csvreader:
                locList.append(row[0])
    except:
        print 'FAIL'
        raise

    return locList

def getHandlers(form):
    selected = form.get('handlerRefName')
    handlerlist = [
        ("Lisa Beyer","urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(LisaBeyer1372717980469)'Lisa Beyer'"),
        ("Victoria Bradshaw", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7267)'Victoria Bradshaw'"),
        ("Zachary Brown","urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(ZacharyBrown1389986714647)'Zachary Brown'"),
        ("Alicja Egbert", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8683)'Alicja Egbert'"),
        ("Madeleine Fang", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7248)'Madeleine W. Fang'"),
        ("Leslie Freund", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7475)'Leslie Freund'"),
        ("Rowan Gard", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(RowanGard1342219780674)'Rowan Gard'"),
        ("Leilani Hunter","urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(LeilaniHunter1389986789001)'Leilani Hunter'"),
        ("Natasha Johnson", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7652)'Natasha Johnson'"),
        ("Brenna Jordan","urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(BrennaJordan1383946978257)'Brenna Jordan'"),
        ("Corri MacEwen", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(9090)'Corri MacEwen'"),
        ("Jon Oligmueller", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(JonOligmueller1372192617217)'Jon Oligmueller'"),
        ("Martina Smith", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(9034)'Martina Smith'"),
        ("Linda Waterfield", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(LindaWaterfield1358535276741)'Linda Waterfield'"),
        ("Jane Williams", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7420)'Jane L. Williams'")
    ]

    handlers = '''
          <select class="cell" name="handlerRefName">
              <option value="None">Select a handler</option>'''

    for handler in handlerlist:
        #print handler
        handlerOption = """<option value="%s">%s</option>""" % (handler[1], handler[0])
        #print "xxxx",selected
        if selected and str(selected) == handler[1]:
            handlerOption = handlerOption.replace('option', 'option selected')
        handlers = handlers + handlerOption

    handlers = handlers + '\n      </select>'
    return handlers, selected


def getReasons(form):
    reason = form.get('reason')

    reasons = '''
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
    reasons = reasons.replace(('option value="%s"' % reason), ('option selected value="%s"' % reason))
    return reasons, reason


def getAppOptions(museum):
    webapps = getWebappList()
    appOptions = ''
    for w in webapps[museum]:
        appOptions += """<option value="%s">%s</option>\n""" % (w, w)
    return '''<select onchange="this.form.submit()" name="selectedapp">\n<option value="None">switch app</option>%s\n</select>''' % appOptions


def getPrinters(form):
    selected = form.get('printer')

    printerlist = [ \
        ("Kroeber Hall", "kroeberBCP"),
        ("Regatta Building", "regattaBCP")
    ]

    printers = '''
          <select class="cell" name="printer">
              <option value="None">Select a printer</option>'''

    for printer in printerlist:
        printerOption = """<option value="%s">%s</option>""" % (printer[1], printer[0])
        if selected and str(selected) == printer[1]:
            printerOption = printerOption.replace('option', 'option selected')
        printers = printers + printerOption

    printers + '\n      </select>'
    return printers, selected


def getFieldset(form):
    selected = form.get('fieldset')

    fields = [ \
        ("Key Info", "keyinfo"),
        ("Name & Desc.", "namedesc"),
        ("Registration", "registration"),
        ("HSR Info", "hsrinfo")
    ]

    fieldset = '''
          <select class="cell" name="fieldset">'''

    for field in fields:
        fieldsetOption = """<option value="%s">%s</option>""" % (field[1], field[0])
        if selected and str(selected) == field[1]:
            fieldsetOption = fieldsetOption.replace('option', 'option selected')
        fieldset = fieldset + fieldsetOption

    fieldset += '\n      </select>'
    return fieldset, selected


def getHierarchies(form):
    selected = form.get('authority')

    authoritylist = [ \
        ("Ethnographic Culture", "concept"),
        ("Places", "places"),
        ("Archaeological Culture", "archculture"),
        ("Ethnographic File Codes", "ethusecode"),
        ("Materials", "material_ca"),
        ("Taxonomy", "taxonomy")
    ]

    authorities = '''
<select class="cell" name="authority">
<option value="None">Select an authority</option>'''

    #sys.stderr.write('selected %s\n' % selected)
    for authority in authoritylist:
        authorityOption = """<option value="%s">%s</option>""" % (authority[1], authority[0])
        #sys.stderr.write('check hierarchy %s %s\n' % (authority[1], authority[0]))
        if selected == authority[1]:
            #sys.stderr.write('found hierarchy %s %s\n' % (authority[1], authority[0]))
            authorityOption = authorityOption.replace('option', 'option selected')
        authorities = authorities + authorityOption

    authorities + '\n </select>'
    return authorities, selected


def getAltNumTypes(form, csid, ant):
    selected = form.get('altnumtype')

    altnumtypelist = [
        ("(none selected)", "(none selected)"),
        ("additional number", "additional number"),
        ("attributed pahma number", "attributed PAHMA number"),
        ("burial number", "burial number"),
        ("moac subobjid", "moac subobjid"),
        ("museum number (recataloged to)", "museum number (recataloged to)"),
        ("previous number", "previous number"),
        (u"previous number (albert bender’s number)", "prev. number (Bender)"),
        (u"previous number (bascom’s number)", "prev. number (Bascom)"),
        (u"previous number (collector’s original number)", "prev. number (collector)"),
        ("previous number (design dept.)", "prev. number (Design)"),
        ("previous number (mvc number, mossman-vitale collection)", "prev. number (MVC)"),
        ("previous number (ucas: university of california archaeological survey)", "prev. number (UCAS)"),
        ("song number", "song number"),
        ("tag", "tag"),
        ("temporary number", "temporary number"),
        ("associated catalog number", "associated catalog number"),
        ("field number", "field number"),
        ("original number", "original number"),
        ("previous museum number (recataloged from)", "prev. number (recataloged from)"),
        (u"previous number (anson blake’s number)", "prev. number (Blake)"),
        (u"previous number (donor's original number)", "prev. number (donor)"),
        ("previous number (uc paleontology department)", "prev. number (Paleontology)"),
        ("tb (temporary basket) number", "tb (temporary basket) number")

    ]

    altnumtypes = \
          '''<select class="cell" name="ant.''' + csid + '''">
              <option value="None">Select a number type</option>'''

    for altnumtype in altnumtypelist:
        if altnumtype[0] == ant:
            altnumtypeOption = """<option value="%s" selected>%s</option>""" % (altnumtype[0], altnumtype[1])
        else:
            altnumtypeOption = """<option value="%s">%s</option>""" % (altnumtype[0], altnumtype[1])
        altnumtypes = altnumtypes + altnumtypeOption

    altnumtypes += '\n      </select>'
    return altnumtypes, selected

def getAgencies(form):
    selected = form.get('agency')

    agencylist = [ \
        ("Bureau of Indian Affairs", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(8452)"),
        ("Bureau of Land Management", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(3784)"),
        ("Bureau of Reclamation", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(6392)"),
        ("California Department of Transportation", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(9068)"),
        ("California State Parks", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(8594)"),
        ("East Bay Municipal Utility District", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(EastBayMunicipalUtilityDistrict1370388801890)"),
        ("National Park Service", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(1533)"),
        ("United States Air Force", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(UnitedStatesAirForce1369177133041)"),
        ("United States Army", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(3021)"),
        ("United States Coast Guard", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(UnitedStatesCoastGuard1342641628699)"),
        ("United States Fish and Wildlife Service", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(UnitedStatesFishandWildlifeService1342132748290)"),
        ("United States Forest Service", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(3120)"),
        ("United States Marine Corps", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(UnitedStatesMarineCorps1365524918536)"),
        ("United States Navy", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(9079)"),
        ("U.S. Army Corps of Engineers", "urn:cspace:pahma.cspace.berkeley.edu:orgauthorities:name(organization):item:name(9133)"),
    ]

    agencies = '''
<select class="cell" name="agency">
<option value="None">Select an agency</option>'''

    for agency in agencylist:
        agencyOption = """<option value="%s">%s</option>""" % (agency[1], agency[0])
        if selected == agency[1]:
            agencyOption = agencyOption.replace('option', 'option selected')
        agencies = agencies + agencyOption

    agencies + '\n </select>'
    return agencies, selected

def getWebappList():
    return {
        'pahma': ['inventory', 'keyinfo', 'objinfo', 'objdetails', 'bulkedit', 'moveobject', 'packinglist', 'movecrate', 'upload',
                  'barcodeprint', 'hierarchyViewer', 'collectionStats', "governmentholdings"],
        'ucbg': ['ucbgAccessions', 'ucbgAdvancedSearch', 'ucbgBedList', 'ucbghierarchyViewer', 'ucbgLocationReport', 'ucbgCollHoldings'],
        'ucjeps': ['ucjepsLocationReport']}



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
    elif updateType == 'movecrate':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Move</th>
      <th style="width:60px; text-align:center;">Not Found</th>
      <th>Notes</th>
    </tr>"""
    elif updateType == 'packinglist':
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
    elif updateType == 'packinglistbyculture':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Count</th>
      <th width="150px;">Location</th>
      <th>Field Collection Place</th>
      <th>P?</th>
    </tr>"""
    elif updateType == 'moveobject':
        return """
    <table><tr>
      <th>Move?</th>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Count</th>
      <th>Location</th>
    </tr>"""
    elif updateType == 'bedlist':
        return """
    <table class="tablesorter" id="sortTable%s"><thead>
    <tr>
      <th data-sort="float">Accession</th>
      <th data-sort="string">Family</th>
      <th data-sort="string">Taxonomic Name</th>
      <th data-sort="string">Rare</th>
      <th data-sort="string">Dead</th>
    </tr></thead><tbody>"""
    elif updateType == 'bedlistxxx' or updateType == 'advsearchxxx':
        return """
    <table class="tablesorter" id="sortTable%s"><thead>
    <tr>
      <th data-sort="float">Accession Number</th>
      <th data-sort="string">Family</th>
      <th data-sort="string">Taxonomic Name</th>
    </tr></thead><tbody>"""
    elif updateType == 'bedlistnone':
        return """
    <table class="tablesorter" id="sortTable"><thead><tr>
      <th data-sort="float">Accession</th>
      <th data-sort="string">Family</th>
      <th data-sort="string">Taxonomic Name</th>
      <th data-sort="string">Rare</th>
      <th data-sort="string">Dead</th>
      <th>Garden Location</th>
    </tr></thead><tbody>"""
    elif updateType in ['locreport','holdings','advsearch']:
        return """
    <table class="tablesorter" id="sortTable"><thead><tr>
      <th data-sort="float">Accession</th>
      <th data-sort="string">Taxonomic Name</th>
      <th data-sort="string">Family</th>
      <th data-sort="string">Garden Location</th>
      <th data-sort="string">Locality</th>
      <th data-sort="string">Rare</th>
      <th data-sort="string">Dead</th>
    </tr></thead><tbody>"""
    elif updateType == 'keyinfoResult' or updateType == 'objinfoResult':
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
    elif updateType == 'barcodeprintlocations':
        return """
    <table width="100%"><tr>
      <th>Locations listed</th>
      <th>Barcode Filename</th>
    </tr>"""
    elif updateType == 'upload':
        return """
    <table width="100%" border="1">
    <tr>
      <th>Museum #</th>
      <th>Note</th>
      <th>Update status</th>
    </tr>"""