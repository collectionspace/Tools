import locale
locale.setlocale(locale.LC_ALL, 'en_US')

# the only other module: isolate postgres calls and connection
import cswaDBobjdetails as DBquery

def formatField(label,condition,value,template,notentered):
   result = '<tr><td class="rightlabel"><b>%s:</b></td>\n' % label
   if condition is None:
      if value is None:
         result +=  '<td><span class="notentered">%s</span></span></td></tr>\n' % notentered
      else:
         result += '<td><span align="left">' + str(value) + "</span></td></tr>\n"
   else:
      if type(condition) == type([]):
         result += '<td><span align="left">'
         for rows in condition:
            for cell in rows:
               if cell:
                  result += cell + ', '
            result += '<br/>'
         result += '</span></td></tr>\n'
      else:
         result += '<td><span align="left">' +  template % str(condition) + "</span></td></tr>\n"
   return result

def doObjectDetails(form,config):
   scannedObjectNumber = form.get('ob.objectnumber')
   objresult = DBquery.getobjinfo(scannedObjectNumber,config)
   if objresult == None: objresult = 18 * [None]
   currlocresult = objresult[17]
   accresult = DBquery.getaccinfo(objresult[15],config)
   if accresult == None: accresult = 3 * [None]
   altnums = DBquery.getaltnums(objresult[16],config)
   if altnums == None: altnums = 3 * [None]
############## FIX BELOW: USE ID INSTEAD OF OBJECTNUMBER ##############
   allaltnumresult = DBquery.getallaltnums(scannedObjectNumber,config)
   assoccultures = DBquery.getassoccultures(objresult[16],config)
############## FIX BELOW: USE CSID INSTEAD OF OBJECTNUMBER ##############
   proddates = DBquery.getproddates(scannedObjectNumber,config)
   if proddates == None: proddates = 3 * [None]
############## FIX BELOW: USE CSID INSTEAD OF OBJECTNUMBER ##############
   objmedia = DBquery.getmedia(scannedObjectNumber,config)
############## FIX BELOW: USE CSID INSTEAD OF OBJECTNUMBER ##############
   parentinfo = DBquery.getparentinfo(scannedObjectNumber,config)
   if parentinfo == None: parentinfo = 13 * [None]
   parentaltnums = DBquery.getparentaltnums(parentinfo[12],config)
   if parentaltnums is None: parentaltnums = 4 * [None]
   parentaccinfo = DBquery.getparentaccinfo(parentinfo[2],config)
   if parentaccinfo == None: parentaccinfo = 3 * [None]
############## FIX BELOW: USE CSID INSTEAD OF OBJECTNUMBER ##############
   childinfo = DBquery.getchildinfo(scannedObjectNumber,config)
   if childinfo == None: childinfo = 4 * [None]
   childlocations = DBquery.getchildlocations(childinfo[2],config)
   if childlocations == None: childlocations = 4 * [None]
      
   print '<span class="objtitle">'
   print '<a href="http://pahma.cspace.berkeley.edu:8180/collectionspace/ui/pahma/html/cataloging.html?csid=%s" target="_blank">%s</a>' % (objresult[15],objresult[0])

   if objresult[6] == None:
      print ": <i>(no object name entered)</i></span>"
   else:
      print "&mdash; " + str(objresult[6]) + "</span>"
      
   print """
    <div style="width:85%; float:left; ">
    <table width="100%">"""
   
######### Alternate Number #########
   print '<tr><td class="rightlabel"><b>Alternate number(s):</b></td><td><span align="left">'
   if altnums[0] == None and parentaltnums[1] != None and str(objresult[10]) == 'yes':
      print "<span class='notentered'>{on record for " + str(parentinfo[1]) + "}:  </span>" + str(parentaltnums[1]),
      if str(parentaltnums[2]) <> 'None':
         print " (" + (parentaltnums[2]),
      if str(parentaltnums[3]) <> 'None':
         if str(parentaltnums[2]) <> 'None':
            print ", " + (parentaltnums[3]) + ")</span></td></tr>"
         else:
            print "( " + (parentaltnums[3]) + ")</span></td></tr>"
      else:
         if parentaltnums[2] != None:
            print ")</span></td></tr>"
         else:
            print "</span></td></tr>"
   elif str(altnums[0]) == 'None' and str(parentaltnums[1]) == 'None':
      print "<span class='notentered'>none entered</span></td></tr>"
   elif str(altnums[0]) == 'None' and str(objresult[10]) == 'no':
      print "<span class='notentered'>none entered</span></td></tr>"
   else:
      print str(altnums[0])
      if str(altnums[1]) <> 'None':
         print " (" + (altnums[1])
      if str(altnums[2]) <> 'None':
         if str(altnums[1]) <> 'None':
            print ", " + (altnums[2]) + ")</span></td></tr>"
         else:
            print "( " + (altnums[2]) + ")</span></td></tr>"
      else:
         if str(altnums[1]) <> 'None':
            print ")</span></td></tr>"
         else:
            print "</span></td></tr>"

######### Current Location #########  NEED TO CONVERT getchildlocations TO FETCHALL()

   if currlocresult == None and str(objresult[10]) == 'no' and childlocations[3] != None:
      print '<tr><td class="rightlabel"><b>Current location:</b></td><td><span align="left">%s : %s</span></td></tr>' % (childlocations[0],childlocations[3])
   else:
      print '<tr><td class="rightlabel"><b>Current location:</b></td><td><span align="left">' + currlocresult + '</span></td></tr>'

   print formatField('Object count',objresult[3],objresult[3],'%s piece(s)','no count entered')
   print formatField('Object type',objresult[1],parentinfo[3],'%s','PARENT: none entered')
   print formatField('Collection manager(s)',objresult[14],parentinfo[11],'%s','none entered')
   print formatField('All alternate number(s)',allaltnumresult,'','%s (%s)','none entered')
   print formatField('Brief Description',objresult[8],None,'%s','none entered')
   print formatField('Distinguishing features',objresult[4],parentinfo[4],'%s','none entered')
   print formatField('Ethnographic file code',objresult[9],parentinfo[7],'%s','none entered')
######### Associated Cultural Group #########  ADD PARENT
   print formatField('Associated cultural group',assoccultures,'','%s','none entered')
#      for assocculture in assoccultures:
#         print str(assocculture[0]) + " "
#         if str(assocculture[1]) <> 'None':
#            print "(" + str(assocculture[1]) + ") "
#         if str(assocculture[2]) <> 'None':
#            print "(" + str(assocculture[2]) + ")<br/>"
#         else:
#            print "<br/>"
#         
#   print "</span></td></tr>"
            
######### Production Date #########  ADD PARENT
   #print formatField('Production date',proddates[1],proddates[2],'(%s)','%s','none entered')
   print '<tr><td class="rightlabel"><b>Production date:</b></span></td><td><span align="left">'
   if str(proddates[1]) == 'None':
      print '<span class="notentered">none entered</span></span></td></tr>'
   else:
      print str(proddates[1])
      if str(proddates[2]) <> 'None':
         print " (" + (proddates[2]) + ")</span></td></tr>"
         
   print formatField('Field collection place',objresult[13],parentinfo[10],'%s','none entered')
   print formatField('Field collection place (vebatim)',objresult[12],parentinfo[9],'%s','none entered')
   print formatField('Collector',objresult[2],parentinfo[5],'%s','none entered')
   print formatField('Donor',accresult[1],parentaccinfo[1],'%s','none entered')
   link = '<a href="http://pahma.cspace.berkeley.edu:8180/collectionspace/ui/pahma/html/acquisition.html?csid=%s" target="_blank">'
   print formatField('Accession',accresult[0],parentaccinfo[0],link,'none entered')
   print formatField('PAHMA legacy catalog',objresult[11],parentinfo[8],'%s','none entered')

   print "</table>"
   print "</div>"

########## Trying to incorporate media ######### NEED TO SHOW PARENT MEDIA IF NO MEDIA
   print """<div style="width:15%; float:left; ">"""
   if objmedia != None:
      for image in objmedia:
          #/blobs/be903851-a2a8-4eee-bf15/derivatives/Thumbnail/content
          link = "http://pahma.cspace.berkeley.edu:8180/cspace-services/blobs/%s/derivatives/%s/content"
          thumb = link % (image[1],'Thumbnail')
          original = link % (image[1],'OriginalJpeg')
          print '<div class="imagecell"><a href="%s" target="_blank"><img src="%s"></a></div>' % (original,thumb)
   else:
      print "no related media"
   print "</div>"
   print '<div style="width: 100%; float:left;"><hr/></div>'
      
   # print "<script>getLastFormElem().focus();</script>"

if __name__ == "__main__":

    # to test this module on the command line you have to pass in two cgi values:
    # $ python cswaOjbectDetails.py "ob.objectnumber=11-11&webapp=objectInfoDev"

    # this will load the config file and attempt to update some records in server identified
    # in that config file!
    import cgi
    from cswaUtils import getConfig
    form = cgi.FieldStorage()
    config = getConfig(form)
    doObjectDetails(form,config)
