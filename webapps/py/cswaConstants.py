#!/usr/bin/env /usr/bin/python
# -*- coding: UTF-8 -*-

import csv, sys, time, os, datetime
import ConfigParser

reload(sys)
sys.setdefaultencoding('utf-8')

def getStyle(schemacolor1):
    return '''
<style type="text/css">
body { margin:10px 10px 0px 10px; font-family: Arial, Helvetica, sans-serif; }
table { }
td { padding-right: 10px; }
th { text-align: left ;color: #666666; font-size: 16px; font-weight: bold; padding-right: 20px;}
h2 { font-size:32px; padding:10px; margin:0px; border-bottom: none; }
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
.zcell { min-width:250px; cell-padding: 2px; font-size: 16px;}
.shortcell { width:180px; cell-padding: 2px; font-size: 16px;}
.objname { font-weight: bold; font-size: 16px; font-style: italic; min-width:200px; }
.objno { font-weight: bold; font-size: 16px; font-style: italic; width:160px; }
.ui-tabs .ui-tabs-panel { padding: 0px; min-height:120px; }
.rdo { text-align: center; width:60px; }
.error {color:red;}
.save { background-color: BurlyWood; font-size:20px; color: #000000; font-weight:bold; vertical-align: middle; text-align: center; }
.shortinput { font-weight: bold; width:150px; }
.subheader { background-color: ''' + schemacolor1 + '''; color: #FFFFFF; font-size: 24px; font-weight: bold; }
.smallheader { background-color: ''' + schemacolor1 + '''; color: #FFFFFF; font-size: 12px; font-weight: bold; }
.veryshortinput { width:60px; }
.xspan { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 12px; min-width:240px; }
th[data-sort]{ cursor:pointer; }
.littlebutton {color: #FFFFFF; background-color: gray; font-size: 11px; padding: 2px; cursor: pointer; }
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
    </tr>"""
    elif fieldSet == 'namedesc':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th></th>
      <th style="text-align:center">Brief Description</th>
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
    </tr>"""
    elif fieldSet == 'objtypecm':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Count</th>
      <th>Object Type</th>
      <th>Collection Manager</th>
      <th>Field Collection Place</th>
      <th>P?</th>
    </tr>"""
    else:
        return "<table><tr>DEBUG</tr>"

def getProhibitedLocations(config):
    #fileName = config.get('files','prohibitedLocations')
    fileName = (os.path.join('..','cfgs','prohibitedLocations.csv'))
    locList = []
    try:
        with open(fileName, 'rb') as csvfile:
            csvreader = csv.reader(csvfile, delimiter="\t")
            for row in csvreader:
                locList.append(row[0])
    except:
        print 'FAILED to load prohibited locations'
        raise

    return locList


def getHandlers(form, institution):
    selected = form.get('handlerRefName')


    if institution == 'bampfa':
        handlerlist = [
            ('Kelly Bennett', 'KB'),
            ('Gary Bogus', 'GB'),
            ('Lisa Calden', 'LC'),
            ('Stephanie Cannizzo', 'SC'),
            ('Genevieve Cottraux', 'GC'),
            ('Laura Hansen', 'LH'),
            ('Michael Meyers', 'MM'),
            ('Scott Orloff', 'SO'),
            ('Pamela Pack', 'PP'),
            ('Julia White', 'JW'),
        ]
    else:

        handlerlist = [
            ("Victoria Bradshaw", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7267)'Victoria Bradshaw'"),
            ("Zachary Brown","urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(ZacharyBrown1389986714647)'Zachary Brown'"),
            ("Alicja Egbert", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(8683)'Alicja Egbert'"),
            ("Madeleine Fang", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7248)'Madeleine W. Fang'"),
            ("Leslie Freund", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7475)'Leslie Freund'"),
            ("Natasha Johnson", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7652)'Natasha Johnson'"),
            ("Brenna Jordan","urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(BrennaJordan1383946978257)'Brenna Jordan'"),
            ("Corri MacEwen", "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(9090)'Corri MacEwen'"),
            ("Karyn Moore","urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(KarynMoore1399567930777)'Karyn Moore'"),
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

    handlers += '\n      </select>'
    return handlers, selected


def getReasons(form, institution):
    reason = form.get('reason')

    if institution == 'bampfa':
        reasons = '''
        <select class="cell" name="reason">
        <options>
        <option value="None" default="yes">(none selected)</option>
        <option value="urn:cspace:bampfa.cspace.berkeley.edu:vocabularies:name(movereason):item:name(2015Inventory1422385313472)'2015 Inventory'" selected>2015 Inventory</option>
        <option value="urn:cspace:bampfa.cspace.berkeley.edu:vocabularies:name(movereason):item:name(movereason001)'Conservation'">Conservation</option>
		<option value="urn:cspace:bampfa.cspace.berkeley.edu:vocabularies:name(movereason):item:name(DataCleanUp1416598052252)'Data Clean Up'">Data Clean Up</option>
		<option value="urn:cspace:bampfa.cspace.berkeley.edu:vocabularies:name(movereason):item:name(movereason002)'Exhibition'">Exhibition</option>
		<option value="urn:cspace:bampfa.cspace.berkeley.edu:vocabularies:name(movereason):item:name(movereason003)'Inventory'">Inventory</option>
		<option value="urn:cspace:bampfa.cspace.berkeley.edu:vocabularies:name(movereason):item:name(movereason004)'Loan'">Loan</option>
		<option value="urn:cspace:bampfa.cspace.berkeley.edu:vocabularies:name(movereason):item:name(movereason005)'New Storage Location'">New Storage Location</option>
		<option value="urn:cspace:bampfa.cspace.berkeley.edu:vocabularies:name(movereason):item:name(movereason006)'Photography'">Photography</option>
		<option value="urn:cspace:bampfa.cspace.berkeley.edu:vocabularies:name(movereason):item:name(movereason007)'Research'">Research</option>
        </options>
        </select>

        '''
    else:
        # these are for PAHMA
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
    <option value="2014 Marchant inventory and move">2014 Marchant inventory and move</option>
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


# NB: not currently used
#def getWebappList():
#    return {
#        'pahma': {'apps': ['inventory', 'keyinfo', 'objinfo', 'objdetails', 'bulkedit', 'moveobject', 'packinglist', 'movecrate', 'pahmaPowerMove', 'upload',
#                  'barcodeprint', 'hierarchyViewer', 'collectionStats', 'governmentholdings']},
#        'ucbg':  {'apps': ['ucbgAccessions', 'ucbgAdvancedSearch', 'ucbgBedList', 'ucbghierarchyViewer', 'ucbgLocationReport', 'ucbgCollHoldings']},
#        'ucjeps':  {'apps': ['ucjepsLocationReport']},
#        'bampfa':  {'apps': ['bamInventory', 'bamIntake', 'bamMoveobject', 'bamPackinglist', 'bamMovecrate', 'bamPowerMove']} }


# NB: not currently used
#def getAppOptions(museum):
#    webapps = getWebappList()
#    appOptions = ''
#    for w in webapps[museum]:
#        appOptions += """<option value="%s">%s</option>\n""" % (w, w)
#    return '''<select onchange="this.form.submit()" name="selectedapp">\n<option value="None">switch app</option>%s\n</select>''' % appOptions


def selectWebapp(form):
    if form.get('webapp') == 'switchapp':
        #sys.stderr.write('%-13s:: %s' % ('switchapp','looking for creds..'))
        username = form.get('csusername')
        password = form.get('cspassword')
        payload = '''
            <input type="hidden" name="checkauth" value="true">
            <input type="hidden" name="csusername" value="%s">
            <input type="hidden" name="cspassword" value="%s">''' % (username, password)
    else:
        payload = ''

    files = os.listdir("../cfgs")

    programName = os.path.basename(__file__).replace('Constants', 'Main') + '?webapp=' # yes, this is fragile!
    apptitles = {}
    serverlabels = {}
    badconfigfiles = ''

    webapps = {}

    for f in files:
        if '.cfg' in f:
            config = ConfigParser.RawConfigParser()
            config.read(os.path.join('../cfgs',f))
            try:
                configfile = f
                configfile = configfile.replace('Dev.cfg','')
                configfile = configfile.replace('Prod.cfg','')
                logo = config.get('info', 'logo')
                updateType = config.get('info', 'updatetype')
                schemacolor1 = config.get('info', 'schemacolor1')
                institution = config.get('info', 'institution')
                apptitle = config.get('info', 'apptitle')
                serverlabel = config.get('info', 'serverlabel')
                # only show dev or prod options in this app
                if not serverlabel in ['production','development']:
                    continue
                serverlabel = serverlabel.replace('production','Prod')
                serverlabel = serverlabel.replace('development','Dev')
                serverlabelcolor = config.get('info', 'serverlabelcolor')
                serverlabels['%s.%s.%s' % (institution,updateType,serverlabel)] = '''<span style="cursor:pointer;color:%s;"><a target="%s" onclick="$('#ucbwebapp').attr('action', '%s').submit(); return false;">%s</a></span>''' % (
                    serverlabelcolor, serverlabel, programName + configfile + serverlabel, serverlabel)
                if not institution in webapps.keys():
                    webapps[institution] = {'apps': {}}
                webapps[institution]['logo'] = logo
                webapps[institution]['apps'][updateType] = [serverlabel,configfile]
                apptitles[updateType] = apptitle
            except:
                badconfigfiles += '<tr><td>%s</td></tr>' % f

    line = '''Content-type: text/html; charset=utf-8


<html><head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">''' + getStyle('lightblue') + '''
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
<title>Select web app</title>
</head>
<body>
<form id="ucbwebapp" method="post">
<h1>UC Berkeley CollectionSpace Deployments: Available Webapps</h1>
<table cellpadding="4px"><tr>
<p>The following table lists the webapps available on this server as of ''' + datetime.datetime.utcnow().strftime(
        "%Y-%m-%dT%H:%M:%SZ") + '''.</p>'''

    for museum in sorted(webapps.keys()):
        line += '<td valign="top"><table><tr style="height:130px; vertical-align:top"><td colspan="3"><h2>%s</h2><img style="max-height:60px; padding:8px" src="%s"></td></tr><tr><th colspan="3"><hr/></th></tr>\n' % (museum,webapps[museum]['logo'])
        listOfWebapps = sorted(webapps[museum]['apps'].keys())
        for webapp in listOfWebapps:
            apptitle = apptitles[webapp] if apptitles.has_key(webapp) else webapp
            line += '<tr class="imagecell" ><th>%s</th>' % apptitle
            for deployment in ['Prod', 'Dev']:
                available = ''
                #available = '''<a target="%s" onclick="$('#ucbwebapp').attr('action', '%s').submit(); return false;">%s</a>''' % (deployment, programName + webapps[museum]['cfgs'][webapp] + deployment.replace('Prod','V321'), webapp + deployment)
                if os.path.isfile(os.path.join('../cfgs',webapps[museum]['apps'][webapp][1] + deployment + '.cfg')):
                    label = '%s.%s.%s' % (museum,webapp,deployment)
                    if label in serverlabels:
                        available = serverlabels[label]
                line += ' <td>%s</td>\n' % available
            line += '</tr>'
        line += '</table></td>\n'
    if badconfigfiles != '':
        line += '<tr><td colspan="2"><h2>%s</h2></td></tr>' % 'bad config files'
        line += badconfigfiles
    line += '''
</tr></table>
<hr/>
<h4>jblowe@berkeley.edu   7 Feb 2013, last revised 14 January 2015</h4>''' + payload + '''
</form>
</body>
</html>'''

    return line


def getPrinters(form):
    selected = form.get('printer')

    printerlist = [
        ("Hearst Gym Basement", "cluster1"),
        ("Marchant", "cluster2")
    ]

    printers = '''
          <select class="cell" name="printer">
              <option value="None">Select a printer</option>'''

    for printer in printerlist:
        printerOption = """<option value="%s">%s</option>""" % (printer[1], printer[0])
        if selected and str(selected) == printer[1]:
            printerOption = printerOption.replace('option', 'option selected')
        printers += printerOption

    printers += '\n      </select>'
    return printers, selected, printerlist


def getFieldset(form):
    selected = form.get('fieldset')

    fields = [
        ("Key Info", "keyinfo"),
        ("Name & Desc.", "namedesc"),
        ("Registration", "registration"),
        ("HSR Info", "hsrinfo"),
        ("Object Type/CM", "objtypecm"),
    ]

    fieldset = '''
          <select class="cell" name="fieldset">'''

    for field in fields:
        fieldsetOption = """<option value="%s">%s</option>""" % (field[1], field[0])
        if selected and str(selected) == field[1]:
            fieldsetOption = fieldsetOption.replace('option', 'option selected')
        fieldset += fieldsetOption

    fieldset += '\n      </select>'
    return fieldset, selected


def getHierarchies(form):
    selected = form.get('authority')

    authoritylist = [
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

    authorities += '\n </select>'
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
        (u"previous number (collector's original number)", "prev. number (collector)"),
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

    altnumtypes = '''<select class="cell" name="ant.''' + csid + '''">
              <option value="None">Select a number type</option>'''

    for altnumtype in altnumtypelist:
        if altnumtype[0] == ant:
            altnumtypeOption = """<option value="%s" selected>%s</option>""" % (altnumtype[0], altnumtype[1])
        else:
            altnumtypeOption = """<option value="%s">%s</option>""" % (altnumtype[0], altnumtype[1])
        altnumtypes = altnumtypes + altnumtypeOption

    altnumtypes += '\n      </select>'
    return altnumtypes, selected

def getObjType(form, csid, ot):
    selected = form.get('objectType')

    objtypelist = [ \
        ("Archaeology", "archaeology"),
        ("Ethnography", "ethnography"),
        ("(not specified)", "(not specified)"),
        ("Documentation", "documentation"),
        ("None (Registration)", "none (Registration)"),
        ("None", "None"),
        ("Sample", "sample"),
        ("Indeterminate", "indeterminate"),
        ("Unknown", "unknown")
    ]

    objtypes = \
          '''<select class="cell" name="ot.''' + csid + '''">
              <option value="None">Select an object type</option>'''

    for objtype in objtypelist:
        if objtype[1] == ot:
            objtypeOption = """<option value="%s" selected>%s</option>""" % (objtype[1], objtype[0])
        else:
            objtypeOption = """<option value="%s">%s</option>""" % (objtype[1], objtype[0])
        objtypes = objtypes + objtypeOption

    objtypes += '\n      </select>'
    return objtypes, selected

def getCollMan(form, csid, cm):
    selected = form.get('collMan')

    collmanlist = [ \
        ("Natasha Johnson", "Natasha Johnson"),
        ("Leslie Freund", "Leslie Freund"),
        ("Alicja Egbert", "Alicja Egbert"),
        ("Victoria Bradshaw", "Victoria Bradshaw"),
        ("Uncertain", "uncertain"),
        ("None (Registration)", "No collection manager (Registration)")
    ]

    collmans = \
          '''<select class="cell" name="cm.''' + csid + '''">
              <option value="None">Select a collection manager</option>'''

    for collman in collmanlist:
        if collman[1] == cm:
            collmanOption = """<option value="%s" selected>%s</option>""" % (collman[1], collman[0])
        else:
            collmanOption = """<option value="%s">%s</option>""" % (collman[1], collman[0])
        collmans = collmans + collmanOption

    collmans += '\n      </select>'
    return collmans, selected
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
        agencies += agencyOption

    agencies += '\n </select>'
    return agencies, selected

def getIntakeFields(fieldset):

    if fieldset == 'intake':

        return [
            ('TR', 20, 'tr','31','fixed'),
            ('Number of Objects:', 5, 'numobjects','1','text'),
            ('Source:', 40, 'pc.source','','text'),
            ('Date in:', 30, 'datein',time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),'text'),
            ('Receipt?', 40, 'receipt','','checkbox'),
            ('Location:', 40, 'lo.location','','text'),
            ('Disposition:', 30, 'disposition','','text'),
            ('Artist/Title/Medium', 10, 'atm','','text'),
            ('Purpose:', 40, 'purpose','','text')
        ]
    elif fieldset == 'objects':

        return [
            ('ID number', 30, 'id','','text'),
            ('Title', 30, 'title','','text'),
            ('Comments', 30, 'comments','','text'),
            ('Artist', 30, 'pc.artist','','text'),
            ('Creation date', 30, 'cd','','text'),
            ('Creation technique', 30, 'ct','','text'),
            ('Dimensions', 30, 'dim','','text'),
            ('Responsible department', 30, 'rd','','text'),
            ('Computed current location', 30, 'lo.loc','','text')
            ]


def getHeader(updateType, institution):
    if updateType == 'inventory':
        if institution == 'bampfa':
            return """
    <table><tr>
      <th>ID number </th>
      <th>Title</th>
      <th>Artist</th>
      <th>Found</th>
      <th style="width:60px; text-align:center;">Not Found</th>
      <th>Notes</th>
    </tr>"""
        else:
            return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Found</th>
      <th style="width:60px; text-align:center;">Not Found</th>
      <th>Notes</th>
    </tr>"""
    elif updateType == 'movecrate' or updateType == 'powermove':
        return """
    <table><tr>
      <th>Museum #</th>
      <th>Object name</th>
      <th>Move</th>
      <th style="width:60px; text-align:center;">Don't Move</th>
      <th>Notes</th>
    </tr>"""
    elif updateType == 'packinglist':

        if institution == 'bampfa':
            return """
    <table><tr>
      <th>ID number</th>
      <th style="width:150px;">Title</th>
      <th>Artist</th>
      <th>Medium</th>
      <th>Dimensions</th>
      <th>Credit Line</th>
    </tr>
        """
        else:
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
      <th data-sort="string">Rare?</th>
      <th data-sort="string">Accession<br/>Dead?</th>
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
      <th data-sort="string">Rare?</th>
      <th data-sort="string">Accession<br/>Dead?</th>
      <th>Garden Location</th>
    </tr></thead><tbody>"""
    elif updateType in ['locreport', 'holdings', 'advsearch']:
        return """
    <table class="tablesorter" id="sortTable"><thead><tr>
      <th data-sort="float">Accession</th>
      <th data-sort="string">Taxonomic Name</th>
      <th data-sort="string">Family</th>
      <th data-sort="string">Garden Location</th>
      <th data-sort="string">Locality</th>
      <th data-sort="string">Rare?</th>
      <th data-sort="string">Accession<br/>Dead?</th>
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
    elif updateType == 'intakeValues':
        return """
    <tr>
      <th>Field</th>
      <th>Value</th>
    </tr>"""
    elif updateType == 'intakeResult':
        return """
    <table width="100%" border="1">
    <tr>
      <th>Museum #</th>
      <th>Note</th>
      <th>Update status</th>
    </tr>"""
    elif updateType == 'intakeObjects':
        return """
    <tr>
      <th>Museum #</th>
      <th>Note</th>
      <th>Update status</th>
    </tr>"""

from operator import itemgetter
from heapq import nlargest
from itertools import repeat, ifilter

class Counter(dict):
    '''Dict subclass for counting hashable objects.  Sometimes called a bag
    or multiset.  Elements are stored as dictionary keys and their counts
    are stored as dictionary values.

    >>> Counter('zyzygy')
    Counter({'y': 3, 'z': 2, 'g': 1})

    '''

    def __init__(self, iterable=None, **kwds):
        '''Create a new, empty Counter object.  And if given, count elements
        from an input iterable.  Or, initialize the count from another mapping
        of elements to their counts.

        >>> c = Counter()                           # a new, empty counter
        >>> c = Counter('gallahad')                 # a new counter from an iterable
        >>> c = Counter({'a': 4, 'b': 2})           # a new counter from a mapping
        >>> c = Counter(a=4, b=2)                   # a new counter from keyword args

        '''
        self.update(iterable, **kwds)

    def __missing__(self, key):
        return 0

    def most_common(self, n=None):
        '''List the n most common elements and their counts from the most
        common to the least.  If n is None, then list all element counts.

        >>> Counter('abracadabra').most_common(3)
        [('a', 5), ('r', 2), ('b', 2)]

        '''
        if n is None:
            return sorted(self.iteritems(), key=itemgetter(1), reverse=True)
        return nlargest(n, self.iteritems(), key=itemgetter(1))

    def elements(self):
        '''Iterator over elements repeating each as many times as its count.

        >>> c = Counter('ABCABC')
        >>> sorted(c.elements())
        ['A', 'A', 'B', 'B', 'C', 'C']

        If an element's count has been set to zero or is a negative number,
        elements() will ignore it.

        '''
        for elem, count in self.iteritems():
            for _ in repeat(None, count):
                yield elem

    # Override dict methods where the meaning changes for Counter objects.

    @classmethod
    def fromkeys(cls, iterable, v=None):
        raise NotImplementedError(
            'Counter.fromkeys() is undefined.  Use Counter(iterable) instead.')

    def update(self, iterable=None, **kwds):
        '''Like dict.update() but add counts instead of replacing them.

        Source can be an iterable, a dictionary, or another Counter instance.

        >>> c = Counter('which')
        >>> c.update('witch')           # add elements from another iterable
        >>> d = Counter('watch')
        >>> c.update(d)                 # add elements from another counter
        >>> c['h']                      # four 'h' in which, witch, and watch
        4

        '''
        if iterable is not None:
            if hasattr(iterable, 'iteritems'):
                if self:
                    self_get = self.get
                    for elem, count in iterable.iteritems():
                        self[elem] = self_get(elem, 0) + count
                else:
                    dict.update(self, iterable) # fast path when counter is empty
            else:
                self_get = self.get
                for elem in iterable:
                    self[elem] = self_get(elem, 0) + 1
        if kwds:
            self.update(kwds)

    def copy(self):
        'Like dict.copy() but returns a Counter instance instead of a dict.'
        return Counter(self)

    def __delitem__(self, elem):
        'Like dict.__delitem__() but does not raise KeyError for missing values.'
        if elem in self:
            dict.__delitem__(self, elem)

    def __repr__(self):
        if not self:
            return '%s()' % self.__class__.__name__
        items = ', '.join(map('%r: %r'.__mod__, self.most_common()))
        return '%s({%s})' % (self.__class__.__name__, items)

    # Multiset-style mathematical operations discussed in:
    #       Knuth TAOCP Volume II section 4.6.3 exercise 19
    #       and at http://en.wikipedia.org/wiki/Multiset
    #
    # Outputs guaranteed to only include positive counts.
    #
    # To strip negative and zero counts, add-in an empty counter:
    #       c += Counter()

    def __add__(self, other):
        '''Add counts from two counters.

        >>> Counter('abbb') + Counter('bcc')
        Counter({'b': 4, 'c': 2, 'a': 1})


        '''
        if not isinstance(other, Counter):
            return NotImplemented
        result = Counter()
        for elem in set(self) | set(other):
            newcount = self[elem] + other[elem]
            if newcount > 0:
                result[elem] = newcount
        return result

    def __sub__(self, other):
        ''' Subtract count, but keep only results with positive counts.

        >>> Counter('abbbc') - Counter('bccd')
        Counter({'b': 2, 'a': 1})

        '''
        if not isinstance(other, Counter):
            return NotImplemented
        result = Counter()
        for elem in set(self) | set(other):
            newcount = self[elem] - other[elem]
            if newcount > 0:
                result[elem] = newcount
        return result

    def __or__(self, other):
        '''Union is the maximum of value in either of the input counters.

        >>> Counter('abbb') | Counter('bcc')
        Counter({'b': 3, 'c': 2, 'a': 1})

        '''
        if not isinstance(other, Counter):
            return NotImplemented
        _max = max
        result = Counter()
        for elem in set(self) | set(other):
            newcount = _max(self[elem], other[elem])
            if newcount > 0:
                result[elem] = newcount
        return result

    def __and__(self, other):
        ''' Intersection is the minimum of corresponding counts.

        >>> Counter('abbb') & Counter('bcc')
        Counter({'b': 1})

        '''
        if not isinstance(other, Counter):
            return NotImplemented
        _min = min
        result = Counter()
        if len(self) < len(other):
            self, other = other, self
        for elem in ifilter(self.__contains__, other):
            newcount = _min(self[elem], other[elem])
            if newcount > 0:
                result[elem] = newcount
        return result


if __name__ == '__main__':

    def handleResult(result,header):
        header = '\n<tr><td>%s<td>' % header
        if type(result) == type(()) and len(result) >= 2:
            return header + result[0]
        elif type(result) == type('string'):
            return header + result
        else:
            raise
            #return result
            #return "\n<h2>some other result</h2>\n"

    form = {}
    config = {}

    result = '<html>\n'

    result += getStyle('blue')

    # all the following return HTML)
    result += '<h2>Dropdowns</h2><table border="1">'
    #result += handleResult(getAppOptions('pahma'),'getAppOptions')
    result += handleResult(getAltNumTypes(form, 'test-csid', 'attributed pahma number'),'getAltNumTypes')
    result += handleResult(getHandlers(form,'bampfa'),'getHandlers: bampfa')
    result += handleResult(getHandlers(form,''),'getHandlers')
    result += handleResult(getReasons(form,'bampfa'),'getReasons:bampfa')
    result += handleResult(getReasons(form,''),'getReasons')
    result += handleResult(getPrinters(form),'getPrinters')
    result += handleResult(getFieldset(form),'getFieldset')
    result += handleResult(getHierarchies(form),'getHierarchies')
    result += handleResult(getAgencies(form),'getAgencies')
    result += '</table>'

    # these two return python objects
    result += '<h2>Tricoder users</h2><table border="1">'
    t = tricoderUsers()
    for k in t.keys():
        result += '<tr><td>%s</td><td>%s</td></tr>' % (k, t[k])
    result += '</table>'
    result += '<h2>Prohibited Locations</h2>'
    for p in getProhibitedLocations(config):
        result += '<li>%s</li>' % p

    result += '<h2>Headers</h2>'
    for h in 'inventory movecrate packinglist packinglistbyculture moveobject bedlist bedlistnone keyinfoResult objinfoResult inventoryResult barcodeprint barcodeprintlocations upload'.split(' '):
        result += '<h3>Header for %s</h3>' % h
        header = getHeader(h,'')
        result += header.replace('<table', '<table border="1" ')
        result += '</table>'

    result += '<h2>KIR/OIR/BOE Fieldset Headers</h2>'
    for h in 'keyinfo namedesc hsrinfo registration'.split(' '):
        result += '<h3>Header for %s</h3>' % h
        header = infoHeaders(h)
        result += header.replace('<table', '<table border="1" ')
        result += '</table>'

    print '''Content-Type: text/html; charset=utf-8

    '''
    print result


    result += '</html>\n'

