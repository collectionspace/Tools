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

import locale
locale.setlocale(locale.LC_ALL, 'en_US')

# the only other module: isolate postgres calls and connection
import badObjectNamesDB

elapsedtime = time.time()

#   #################################### Collection Stats web app #######################################

def doGetNamesOverSixtyCharsLong(config):

   unixruntime = time.time()
   isoruntime = datetime.datetime.fromtimestamp(int(unixruntime)).strftime('%Y-%m-%d %H:%M:%S')

   badobjectnames = badObjectNamesDB.getnamesoversixtycharslong(config)

   print """<h2 text-align="center">There are """ + str(len(badobjectnames)) + " objects with names over 60 characters long:</h2><i>(Note: full names are shown, so any truncation is a pre-CSpace artifact)</i><br/>"
   print """<table><tr><th>Museum No.</th><th width="500px">Object name</th></tr>"""
   
   icount = -1
   for badobjectname in badobjectnames:
      icount += 1
      objectnumber = badobjectnames[icount][0]
      objectname = badobjectnames[icount][1]
      description = badobjectnames[icount][2]
      objectcsid = badobjectnames[icount][3]
      objecturl = "http://pahma.cspace.berkeley.edu:8180/collectionspace/ui/pahma/html/cataloging.html?csid=" + str(objectcsid)
      print '''<tr><td><a href="''' + str(objecturl) + '''" target="_blank">''' + str(objectnumber) + "</a></td><td>" + str(objectname) + "</td></tr>"

   print "</table>"

# ###############################

def starthtml(form,config):
   
    if config == False:
	print selectWebapp()
        sys.exit(0)
 
    logo = config.get('info','logo')
    schemacolor1 = config.get('info','schemacolor1')
    serverlabel = config.get('info','serverlabel')
    serverlabelcolor = config.get('info','serverlabelcolor')
    apptitle = config.get('info','apptitle')
    updateType = config.get('info','updatetype')

    location1 = str(form.getvalue("lo.location1")) if form.getvalue("lo.location1") else ''
    location2 = str(form.getvalue("lo.location2")) if form.getvalue("lo.location2") else ''
    num2ret   = str(form.getvalue('num2ret')) if str(form.getvalue('num2ret')).isdigit() else '50'

    button = '''<input id="actionbutton" class="save" type="submit" value="Refresh" name="action">'''
    otherfields = '''  '''
    divsize = '''<div id="sidiv" style="position:relative; width:1000px; height:750px; color:#CC0000; ">'''

    return '''Content-type: text/html; charset=utf-8

    
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
h2 { font-size:28px; padding:5px; margin:0px; border-bottom: none; text-align:center; }
h3 { font-size:12px; float:left; color:white; background:black; }
p { padding:10px 10px 10px 10px; }

button { font-size: 150%; width:85px; text-align: center; text-transform: uppercase;}

.objtitle { font-size:28px; float:left; padding:2px; margin:0px; border-bottom: thin dotted #aaaaaa; color: #000000; }
.objsubtitle { font-size:28px; float:left; padding:2px; margin:0px; border-bottom: thin dotted #aaaaaa; font-style: italic; color: #999999; }

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
.save { background-color: BurlyWood; font-size:20px; color: #000000; font-weight:bold; vertical-align: middle; text-align: center; }
.shortinput { font-weight: bold; width:150px; }
.subheader { background-color: ''' + schemacolor1 + '''; color: #FFFFFF; font-size: 24px; font-weight: bold; }
.veryshortinput { width:60px; }
.xspan { color: #000000; background-color: #FFFFFF; font-weight: bold; font-size: 12px; }


</style>
<style type="text/css">
  /*<![CDATA[*/
    @import "../css/jquery-ui-1.8.22.custom.css";
  /*]]>*/
  </style>
<script type="text/javascript" src="../js/jquery-1.7.2.min.js"></script>
<script type="text/javascript" src="../js/jquery-ui-1.8.22.custom.min.js"></script>
<script type="text/javascript" src="../js/provision.js"></script>
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
  <tbody><tr><td width="3%">&nbsp;</td><td align="center">''' + divsize + '''
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
    </table>'''

# ###############################

def endhtml(config,elapsedtime):

    #user = form.getvalue('user')
    count = form.getvalue('count')
    connect_string = config.get('connect','connect_string')
    return '''
  <table width="100%">
    <tbody>
    <tr><td colspan="5"><hr></td></tr>
    <tr>
      <td width="180px" class="xspan">''' + time.strftime("%b %d %Y %H:%M:%S", time.localtime()) + '''</td>
      <td width="120px" class="cell">elapsed time: </td>
      <td class="xspan">''' + ('%8.2f' % elapsedtime) + ''' seconds</td>
      <td style="text-align: right;" class="cell">powered by </td>
      <td style="text-align: right;width: 170;" class="cell"><img src="http://collectionspace.org/sites/all/themes/CStheme/images/CSpaceLogo.png" height="30px"></td>
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

# ###############################

if __name__ == "__main__":

    #fileName = 'badObjectNamesV321.cfg'
    fileName = 'badObjectNamesDev.cfg'
    config = ConfigParser.RawConfigParser()
    config.read(fileName)
    form    = cgi.FieldStorage()
    
    print starthtml(form,config)

    doGetNamesOverSixtyCharsLong(config)
    
    elapsedtime = time.time() - elapsedtime
    print endhtml(config,elapsedtime)
