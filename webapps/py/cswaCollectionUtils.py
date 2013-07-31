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
#import cgitb; cgitb.enable(display=0, logdir="/logs")  # for troubleshooting
import re

import locale
locale.setlocale(locale.LC_ALL, '')

# the only other module: isolate postgres calls and connection
import cswaCollectionDB

# #############################################################################################################
############ For more aesthetic on-screen tables, as some of the labels are too long for a single line ########

def makeprettylabel(label):
   
   if str(label) == 'No collection manager (Registration)': label = 'None (Registration)'
   elif str(label) == 'Cat.  1: California (archaeology and ethnology)': label = 'Cat. 1: California'
   elif str(label) == 'Cat.  2 - North America (except Mexico and Central America)': label = 'Cat. 2: North America'
   elif str(label) == 'Cat.  3 - Mexico, Central America, and Caribbean Area': label = 'Cat. 3: Mexico, Cent. Am., and Carib.'
   elif str(label) == 'Cat.  4 - South America (Uhle Collection)': label = 'Cat. 4: South America (Uhle)'
   elif str(label) == 'Cat.  5 - Africa (except the Hearst Reisner Egyptian Collection)': label = 'Cat. 5: Africa (except Reisner)'
   elif str(label) == 'Cat.  6 - Ancient Egypt (the Hearst Reisner Egyptian Collection)': label = 'Cat. 6: Ancient Egypt (Reisner)'
   elif str(label) == 'Cat.  7 - Europe (incl. Russia west of Urals, north of Caucasus)': label = 'Cat. 7: Europe'
   elif str(label) == 'Cat.  8 - Classical Mediterranean regions': label = 'Cat. 8: Classical Mediterranean'
   elif str(label) == 'Cat.  9 - Asia (incl. Russia east of Urals)': label = 'Cat. 9: Asia'
   elif str(label) == 'Cat. 10 - Philippine Islands': label = 'Cat. 10: Philippine Islands'
   elif str(label) == 'Cat. 11 - Oceania (incl. Australia)': label = 'Cat. 11: Oceania (incl. Australia)'
   elif str(label) == 'Cat. 13 - Photographic prints (without negatives)': label = 'Cat. 13: Photographic prints'
   elif str(label) == 'Cat. 15 - Photographic negatives': label = 'Cat. 15: Photographic negatives'
   elif str(label) == 'Cat. 16 - South America (except Uhle Collection)': label = 'Cat. 16: South America (except Uhle)'
   elif str(label) == 'Cat. 17 - Drawings and Paintings': label = 'Cat. 17: Drawings and paintings'
   elif str(label) == 'Cat. 18 - Malaysia (incl. Indonesia, excl. Philippine Islands)': label = 'Cat. 18: Malaysia'
   elif str(label) == 'Cat. 22 - Rubbings of Greek & Latin Inscriptions': label = 'Cat. 22: Rubbings'
   elif str(label) == 'Cat. 23 - No provenience (most of catalog deleted)': label = 'Cat. 23: No provenience'
   elif str(label) == 'Cat. 25 - Kodachrome color transparencies': label = 'Cat. 25: Color slides'
   elif str(label) == 'Cat. 26 - Motion picture film': label = 'Cat. 26: Motion picture film'
   elif str(label) == 'Cat. 28 - unknown (retired catalog)': label = 'Cat. 28: unknown (retired catalog)'
   elif str(label) == 'Cat. B - Barr collection': label = 'Cat. B: Barr collection'
   elif str(label) == 'Cat. K - Kelly collection': label = 'Cat. K: Kelly collection'
   elif str(label) == 'Cat. L - Lillard Collection': label = 'Cat. L: Lillard collection'
   elif str(label) == 'NAGPRA-associated Funerary Objects': label = 'NAGPRA AFOs'
   elif str(label) == 'Faunal Remains': label = 'Faunal remains'
   elif str(label) == 'Human Remains': label = 'Human remains'

   return label

# ################################ Set the title of the chart ###############################

def getcharttitle(statgroup, statmetric):

    if statgroup == 'totalCounts':
       if statmetric == 'totalMusNoCount':
          chartTitle = "Total Museum Numbers"
       elif statmetric == 'totalObjectCount':
          chartTitle = "Total Object Counts"
       elif statmetric == 'trueObjectCount':
          chartTitle = "True Object Counts"
       elif statmetric == 'totalPieceCount':
          chartTitle = "Total Piece Counts"
       elif statmetric == 'truePieceCount':
          chartTitle = "True Piece Counts"
    elif statgroup <> 'totalCounts':
       if statmetric == 'totalMusNoCount':
          chartTitle1 = "Museum Numbers"
       elif statmetric == 'totalObjectCount':
          chartTitle1 = "Object count (uncorrected)"
       elif statmetric == 'trueObjectCount':
          chartTitle1 = "Object Count"
       elif statmetric == 'totalPieceCount':
          chartTitle1 = "Piece count (uncorrected)"
       elif statmetric == 'truePieceCount':
          chartTitle1 = "Piece Count"

    if statgroup == 'totalCounts':
       chartTitle2 = ""
    elif statgroup == 'objByObjType':
       chartTitle2 = " by Object Type "
    elif statgroup == 'objByLegCat':
       chartTitle2 = " by Catalog or Department"
    elif statgroup == 'objByCollMan':
       chartTitle2 = " by Collection Manager "
    elif statgroup == 'objByAccStatus':
       chartTitle2 = " by Accession Status"
    elif statgroup == 'objByFileCode':
       chartTitle2 = " by Ethnographic File Code"

    chartTitle = str(chartTitle1) + str(chartTitle2)
    return chartTitle

# ###############################

def plotthedata(retrievedstats, statgroup, statmetric, chartType, imageWidth, imageHeight):
   
    chartTitle = getcharttitle(statgroup, statmetric)

    chartType = ""
    legend = ""
    otherFields = ''
    if statgroup == "objByObjType" or statgroup == "objByCollMan" :
        chartType = "PieChart"
        legend = "right"
        imageHeight = 400
    else:
        chartType = "BarChart"
        legend = "bottom"
        imageHeight = 750

    if statgroup == "objByAccStatus":
       packages, makeDivs, categories, stat, divs, otherFields = prepAccStats(retrievedstats, statmetric, chartTitle, imageWidth, imageHeight)
    else:
       packages, makeDivs, categories, stat, divs, otherFields = prepOthers(retrievedstats, statmetric, chartTitle, imageWidth, imageHeight, legend, chartType)

    chartHTML = '''<div>
    <center><span style="font-size:18pt">''' + chartTitle +'''</span></center></div>
    ''' + makeDivs + '''
    <script>
      google.load('visualization', '1', {'packages':[''' + packages + ''']});
      google.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable(['''
    chartHTML += categories + "\n" + stat[:-2] + ''']);\n''' + otherFields + '''\n</script>'''
    print chartHTML
    print "<br/><hr/>"

# ###############################

def prepAccStats(retrievedstats, statmetric, chartTitle, imgW, imgH):
   accStatusBlocked = ['not located', 'not received', 'intended for transfer', 'returned loan object', 'intended for repatriation', 'missing in inventory', \
                       'red-lined', 'on loan (=borrowed)', 'pending repatriation', 'object mount', 'irregular Museum number']
   packages = "'controls'"
   makeDivs = '''<div id="dashboard"></div><div id="''' + statmetric + '''_con"></div><div id="''' + chartTitle + '''"></div>'''
   categories = '''['Category', 'Subcategory', ''' + "'" + makeNiceStatMetrics(statmetric) + "'" + '''],'''
   stat = ''
   icount = -1
   for retrievedstat in retrievedstats:
      icount += 1
      if retrievedstats[icount][0] in accStatusBlocked:
         continue
      stat += "['" + makeTersePrettyLabel(retrievedstats[icount][0]) + "', '" + getAccCat(retrievedstats[icount][0]) + "', " + str(retrievedstats[icount][1]) + "],\n"
   divs = ''
   otherFields = '''var barChart''' + statmetric + ''' = new google.visualization.ChartWrapper({
    'chartType': 'PieChart',
    'containerId':''' + "'" + chartTitle + "'" + ''',
    'options': {
        'width':''' + str(imgW) + ''',
        'height':''' + str(imgH) + ''',
        'legend.alignment':'center',
        'tooltip': {showColorCode: true},
        'pieResidueSliceLabel':'Other Designations',
        'pieSliceText': 'none',
        'slices': [{color: '#D68448'}, {color: '#AD8142'}, {color: '#ED841A'}, {color: '#ED641D'}, {color: '#E3AB28'}, {color: '#D68448'}, {color: '#AD8142'}, {color: '#ED841A'}, {color: '#ED641D'}, {color: '#E3AB28'}],
        'colors': [{color: '#ED841A'}],
        chartArea: {left:"21%",top:"5%",width:"70%",height:"85%"},
    },
    // Configure the barchart to use columns 0 (Category) and 2 (Number of Museum Numbers, Objects, Pieces)
    'view': {'columns': [0, 2]}
  });
  var accStatusFilter_''' + statmetric + ''' = new google.visualization.ControlWrapper({
    'controlType': 'CategoryFilter',
    'containerId':''' + "'" + statmetric + "_con" + "'" + ''',
    'options': {
      'filterColumnLabel': 'Subcategory',
      'ui': {
        'labelStacking': 'vertical',
        'allowTyping': false,
        'allowMultiple': false
      }
    }
  });
  var dashboard = new google.visualization.Dashboard(document.getElementById('dashboard'))
     .bind(accStatusFilter_''' + statmetric + ''', barChart''' + statmetric + ''').draw(data);
  }'''
   return packages, makeDivs, categories, stat, divs, otherFields

# ###############################

def prepOthers(retrievedstats, statmetric, chartTitle, imgW, imgH, legend, chartType):
   packages = "'corechart'"
   makeDivs = '''<div id="''' + chartTitle + '''"></div>'''
   categories = '''['Category', ''' + "'" + makeNiceStatMetrics(statmetric) + "'" + '''],'''
   stat = ''
   icount = -1
   for retrievedstat in retrievedstats:
      icount += 1
      stat += "['" + str(makeTersePrettyLabel(retrievedstats[icount][0])) + "', " + str(retrievedstats[icount][1]) + "],\n"
   divs = ''
   otherFields = '''var options = {'width':''' + str(imgW) + ''',
                       'height':''' + str(imgH) + ''',
                       'legend':''' + "'" + legend + "'" + ''',
                       'legend.alignment':'center',
                       'tooltip': {showColorCode: true},
                       'pieResidueSliceLabel':'Other Designations',
                       'pieSliceText': 'none',
                       'slices': [{color: '#D68448'}, {color: '#AD8142'}, {color: '#ED841A'}, {color: '#ED641D'}, {color: '#E3AB28'}],
                       'colors': [{color: '#ED841A'}],
                       chartArea: {left:"21%",top:"5%",width:"70%",height:"85%"}};

        // Instantiate and draw our chart, passing in some options.
        var chart = new google.visualization.''' + chartType + '''(document.getElementById(''' + "'" + chartTitle + "'" + '''));
        chart.draw(data, options);
      }'''
   return packages, makeDivs, categories, stat, divs, otherFields

# ###############################

def getAccCat(accStatus):
   if str(accStatus) == 'accessioned':                      accStatus = 'Accession Status'
   elif str(accStatus) == 'number not used':                accStatus = 'Accession Status'
   elif str(accStatus) == 'deaccessioned':                  accStatus = 'Accession Status'
   elif str(accStatus) == 'accession status unclear':       accStatus = 'Accession Status'
   elif str(accStatus) == 'None':                           accStatus = 'Accession Status'
   elif str(accStatus) == '(unknown)':                      accStatus = 'Accession Status'
   elif str(accStatus) == 'partially deaccessioned':        accStatus = 'Accession Status'
   elif str(accStatus) == 'not cataloged':                  accStatus = 'Accession Status'
   elif str(accStatus) == 'recataloged':                    accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'transferred':                    accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'missing':                        accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'repatriated':                    accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'sold':                           accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'exchanged':                      accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'discarded':                      accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'partially exchanged':            accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'destructive analysis':           accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'destroyed':                      accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'partially recataloged':          accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'stolen':                         accStatus = 'Deaccession Reason'
   elif str(accStatus) == 'culturally affiliated':          accStatus = 'Cultural Affiliation'
   elif str(accStatus) == 'culturally unaffiliated':        accStatus = 'Cultural Affiliation'
   else:                                                    accStatus = 'Other'

   return accStatus

# ###############################

def makethreecharts (dbsource, charttype, statgroup, config):

    statmetric = 'totalMusNoCount'
    retrievedCounts = cswaCollectionDB.lateststatsforstatgroupbycounttype(dbsource, statgroup, statmetric, config)
    #print retrievedCounts
    plotthedata(retrievedCounts, statgroup, statmetric, charttype, 1250, 300)

    statmetric = 'trueObjectCount'
    retrievedCounts = cswaCollectionDB.lateststatsforstatgroupbycounttype(dbsource, statgroup, statmetric, config)    
    plotthedata(retrievedCounts, statgroup, statmetric, charttype, 1250, 300)

    statmetric = 'truePieceCount'
    retrievedCounts = cswaCollectionDB.lateststatsforstatgroupbycounttype(dbsource, statgroup, statmetric, config)    
    plotthedata(retrievedCounts, statgroup, statmetric, charttype, 1250, 300)

# ###############################

def maketableofcounts (dbsource, sectiontitle, statgroup, config):
   
   tableresults = cswaCollectionDB.latestcollectionstats(dbsource, statgroup, config)

   #print """<table border="0"><tr>
   #<th class="statheader">""" + sectiontitle + """</th><th class="statheader" colspan="2">Museum Nos.</th><th class="statheader" colspan="2">Total object count</th>
   #<th class="statheader" colspan="2">True object count</th><th class="statheader" colspan="2">Total piece count</th><th class="statheader" colspan="2">True piece count</th></tr>"""
   
   print """<table border="0"><tr>
   <th class="statheader">""" + sectiontitle + """</th><th class="statheader" colspan="2">Museum Nos.</th><th class="statheader" colspan="2">Object Counts</th>
   <th class="statheader" colspan="2">Piece Counts</th></tr>"""
   

   icount = -1
   for tableresult in tableresults:
      icount += 1
      labelverbatim = tableresults[icount][0]
      label = makeprettylabel(labelverbatim)
      totalMusNoCount = tableresults[icount][1]
      percentOfMuseumNos = round(tableresults[icount][2],3)
      totalObjectCount = tableresults[icount][3]
      percentOfTotalObjects = round(tableresults[icount][4],3)
      trueObjectCount = tableresults[icount][5]
      percentOfTrueObjects = round(tableresults[icount][6],3)
      totalPieceCount = tableresults[icount][7]
      percentOfTotalPieces = round(tableresults[icount][8],3)
      truePieceCount = tableresults[icount][9]
      percentOfTruePieces = round(tableresults[icount][10],3)
      dateOfCounts = tableresults[icount][11]
         
      #print """<tr><td  width="250px" class="stattitle">""" + str(label) + """</td>
      #  <td width="75px" class="statnumber">""" + str(locale.format("%d", int(totalMusNoCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfMuseumNos) + """ %)</td>
      #  <td width="75px" class="statnumber">""" + str(locale.format("%d", int(totalObjectCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTotalObjects) + """ %)</td>
      #  <td width="75px" class="statnumber">""" + str(locale.format("%d", int(trueObjectCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTrueObjects) + """ %)</td>
      #  <td width="75px" class="statnumber">""" + str(locale.format("%d", int(totalPieceCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTotalPieces) + """ %)</td>
      #  <td width="75px" class="statnumber">""" + str(locale.format("%d", int(truePieceCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTruePieces) + """ %)</td></tr>"""

      print """<tr><td  width="250px" class="stattitle">""" + str(label) + """</td>
        <td width="75px" class="statnumber">""" + str(locale.format("%d", int(totalMusNoCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfMuseumNos) + """ %)</td>
        <td width="75px" class="statnumber">""" + str(locale.format("%d", int(trueObjectCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTrueObjects) + """ %)</td>
        <td width="75px" class="statnumber">""" + str(locale.format("%d", int(truePieceCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTruePieces) + """ %)</td></tr>"""


   print "</table>"
   print "<hr/>"

# ###############################

def makeglancetab(dbsource, config):

   ##Quick and dirty. Should be done with queries

   tableresults = cswaCollectionDB.latestcollectionstats(dbsource, "objByObjType", config)

   totalMusNo = totalObjNo = totalPieceNo = 0
   icount = -1
   for tableresult in tableresults:
      icount += 1
      totalMusNo += tableresults[icount][1]
      totalObjNo += tableresults[icount][5]
      totalPieceNo += tableresults[icount][9]
   objTypes = icount + 1
   icount = 0
   tableresults = cswaCollectionDB.latestcollectionstats(dbsource, "objByLegCat", config)
   for tableresult in tableresults:
      icount += 1
   cats = icount
   icount = 0
   tableresults = cswaCollectionDB.latestcollectionstats(dbsource, "objByAccStatus", config)
   for tableresult in tableresults:
      icount += 1
   accStats = icount
   icount = 0
   tableresults = cswaCollectionDB.latestcollectionstats(dbsource, "objByCollMan", config)
   for tableresult in tableresults:
      icount += 1
   collMan = icount
   icount = 0
   tableresults = cswaCollectionDB.latestcollectionstats(dbsource, "objByFileCode", config)
   for tableresult in tableresults:
      icount += 1
   fileCode = icount
   
   print '''<div id="tabs-1" style="width:inherit; height:inherit; text-align:left; font-size:14px">
    <span><p><img src="../images/skyphos.png" style="float:right" alt="Skyphos">
      The Phoebe A. Hearst Museum of Anthropology's collection contains:
      <ul>
        <li><b>''' + str(locale.format("%d", int(totalMusNo), grouping=True)) + '''</b> Total Museum Numbers</li>
        <li><b>''' + str(locale.format("%d", int(totalObjNo), grouping=True)) + '''</b> Total Objects</li>
        <li><b>''' + str(locale.format("%d", int(totalPieceNo), grouping=True)) + '''</b> Total Pieces</li>
      </ul>
      Distributed among:
      <ul>
        <li><b>''' + str(objTypes) + '''</b> <a href="#tab2" id="gototab2" title="Object Types"><u>Object Types</u></a></li>
        <li><b>''' + str(cats) + '''</b> <a href="#tab3" id="gototab3" title="Catalogs"><u>Catalogs</u></a></li>
        <li><b>''' + str(accStats) + '''</b> <a href="#tab4" id="gototab4" title="Accession Statuses"><u>Accession Statuses</u></a></li>
        <li><b>''' + str(collMan) + '''</b> <a href="#tab5" id="gototab5" title="Collection Managers"><u>Collection Managers</u></a></li>
        <li><b>''' + str(fileCode) + '''</b> <a href="#tabs6" id="gototab6" title="Use Codes"><u>Ethnographic Use Codes</u></a></li>
      </ul>
    </p></span>
  </div>'''

# ###############################

def getCharts(statgroup, sectiontitle):
   print '''<center><span style="font-size:18pt">Museum Numbers by ''' + sectiontitle[3:].title() + '''</span></center>
   <img src="../images/musno''' + statgroup[5:]+ '''.png" alt="Museum Numbers by ''' + sectiontitle[3:].title() + '''">
   <br/><hr/>
   <center><span style="font-size:18pt">Object Counts by ''' + sectiontitle[3:].title() + '''</span><center>
   <img src="../images/objcount''' + statgroup[5:]+ '''.png" alt="Object Counts by ''' + sectiontitle[3:].title() + '''">
   <br/><hr/>
   <center><span style="font-size:18pt">Piece Counts by ''' + sectiontitle[3:].title() + '''</span><center>
   <img src="../images/piececount''' + statgroup[5:]+ '''.png" alt="Piece Counts by ''' + sectiontitle[3:].title() + '''">
   <br/><hr/>'''

############ For terser, more aesthetic on-screen tables, as some of the labels are too long for a single line ########

def makeTersePrettyLabel(label):
   # Shortens labels to <= 32 characters
   #                                                                                      label = '12345678901234567890123456789012'
   if str(label) == 'No collection manager (Registration)':                               label = 'None (Registration)'
   elif str(label) == 'Cat.  1: California (archaeology and ethnology)':                  label = 'Cat. 1: California'
   elif str(label) == 'Cat.  2 - North America (except Mexico and Central America)':      label = 'Cat. 2: North America'
   elif str(label) == 'Cat.  3 - Mexico, Central America, and Caribbean Area':            label = 'Cat. 3: Mexico, C. Am., & Carib.'
   elif str(label) == 'Cat.  4 - South America (Uhle Collection)':                        label = 'Cat. 4: South America (Uhle)'
   elif str(label) == 'Cat.  5 - Africa (except the Hearst Reisner Egyptian Collection)': label = 'Cat. 5: Africa (except Reisner)'
   elif str(label) == 'Cat.  6 - Ancient Egypt (the Hearst Reisner Egyptian Collection)': label = 'Cat. 6: Ancient Egypt (Reisner)'
   elif str(label) == 'Cat.  7 - Europe (incl. Russia west of Urals, north of Caucasus)': label = 'Cat. 7: Europe'
   elif str(label) == 'Cat.  8 - Classical Mediterranean regions':                        label = 'Cat. 8: Classical Mediterranean'
   elif str(label) == 'Cat.  9 - Asia (incl. Russia east of Urals)':                      label = 'Cat. 9: Asia'
   elif str(label) == 'Cat. 10 - Philippine Islands':                                     label = 'Cat. 10: Philippine Islands'
   elif str(label) == 'Cat. 11 - Oceania (incl. Australia)':                              label = 'Cat. 11: Oceania (w/ Australia)'
   elif str(label) == 'Cat. 13 - Photographic prints (without negatives)':                label = 'Cat. 13: Photographic prints'
   elif str(label) == 'Cat. 15 - Photographic negatives':                                 label = 'Cat. 15: Photographic negatives'
   elif str(label) == 'Cat. 16 - South America (except Uhle Collection)':                 label = 'Cat. 16: So. America (not Uhle)'
   elif str(label) == 'Cat. 17 - Drawings and Paintings':                                 label = 'Cat. 17: Drawings and paintings'
   elif str(label) == 'Cat. 18 - Malaysia (incl. Indonesia, excl. Philippine Islands)':   label = 'Cat. 18: Malaysia'
   elif str(label) == 'Cat. 22 - Rubbings of Greek & Latin Inscriptions':                 label = 'Cat. 22: Rubbings'
   elif str(label) == 'Cat. 23 - No provenience (most of catalog deleted)':               label = 'Cat. 23: No provenience'
   elif str(label) == 'Cat. 25 - Kodachrome color transparencies':                        label = 'Cat. 25: Color slides'
   elif str(label) == 'Cat. 26 - Motion picture film':                                    label = 'Cat. 26: Motion picture film'
   elif str(label) == 'Cat. 28 - unknown (retired catalog)':                              label = 'Cat. 28: unknown (retired cat.)'
   elif str(label) == 'Cat. B - Barr collection':                                         label = 'Cat. B: Barr collection'
   elif str(label) == 'Cat. K - Kelly collection':                                        label = 'Cat. K: Kelly collection'
   elif str(label) == 'Cat. L - Lillard Collection':                                      label = 'Cat. L: Lillard collection'
   elif str(label) == 'NAGPRA-associated Funerary Objects':                               label = 'NAGPRA AFOs'
   elif str(label) == 'Faunal Remains':                                                   label = 'Faunal remains'
   elif str(label) == 'Human Remains':                                                    label = 'Human remains'

   return label

# ############### Makes nicer looking names for statMetrics ################

def makeNiceStatMetrics(label):
   if str(label) == 'totalMusNoCount':                      label = 'Total Museum Numbers'
   elif str(label) == 'trueObjectCount':                    label = 'Object Count'
   elif str(label) == 'truePieceCount':                     label = 'Piece Count'

   return label
