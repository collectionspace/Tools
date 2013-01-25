#!/usr/bin/env /usr/bin/python

import time
import sys
import cgi
import pgdb
import locale

locale.setlocale(locale.LC_ALL, 'en_US')

timeoutcommand = 'set statement_timeout to 300000'

# ###############################

def getparentinfo(museumNumber,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getparentsinfo = """
   SELECT c1.objectnumber, 
    c2.objectnumber AS parent, 
    h3.name as parentcsid, 
    c2.collection, 
    c2.distinguishingfeatures,
    CASE WHEN (fc.item IS NOT NULL AND fc.item <> '') THEN SUBSTRING(fc.item, POSITION(')''' IN fc.item)+2, LENGTH(fc.item)-POSITION(')''' IN fc.item)-2) END AS collector,
    n.objectname,
    CASE WHEN (efc.item IS NOT NULL AND efc.item <> '') THEN SUBSTRING(efc.item, POSITION(')''' IN efc.item)+2, LENGTH(efc.item)-POSITION(')''' IN efc.item)-2) END AS filecode,
    cop.pahmatmslegacydepartment,
    cop.pahmafieldlocverbatim,
    CASE WHEN (fcp.item IS NOT NULL AND fcp.item <> '') THEN SUBSTRING(fcp.item, POSITION(')''' IN fcp.item)+2, LENGTH(fcp.item)-POSITION(')''' IN fcp.item)-2) END AS site,
    cm.item,
    c2.id
FROM collectionobjects_common c1
JOIN collectionobjects_pahma cp1 ON (c1.id = cp1.id)
JOIN hierarchy h1 ON (c1.id = h1.id)
JOIN relations_common rc ON (h1.name=rc.subjectcsid AND rc.objectdocumenttype='CollectionObject')
JOIN hierarchy h2 ON (rc.objectcsid = h2.name)
JOIN collectionobjects_common c2 ON (h2.id = c2.id)
JOIN hierarchy h3 ON (c2.id = h3.id)
JOIN collectionobjects_pahma cp2 ON (c2.id = cp2.id)
LEFT OUTER JOIN hierarchy h4 ON (c2.id = h4.parentid AND h4.primarytype='objectNameGroup' AND h4.pos=0)
LEFT OUTER JOIN objectnamegroup n ON (n.id=h4.id)
LEFT OUTER JOIN collectionobjects_common_fieldcollectors fc ON (fc.id=c2.id AND fc.pos=0)
LEFT OUTER JOIN collectionobjects_pahma_pahmaethnographicfilecodelist efc ON (c2.id=efc.id AND efc.pos=0)
JOIN collectionobjects_pahma cop ON (c2.id=cop.id)
LEFT OUTER JOIN collectionobjects_pahma_pahmafieldcollectionplacelist fcp ON (c2.id=fcp.id AND fcp.pos=0)
LEFT OUTER JOIN collectionobjects_common_responsibledepartments cm ON (c2.id=cm.id AND cm.pos=0)
WHERE cp2.iscomponent = 'no' AND c1.objectnumber = '%s'""" % museumNumber
    
    objects.execute(getparentsinfo)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

# ###############################

def getchildinfo(museumNumber,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getchildinfo = """
   SELECT c1.objectnumber, 
    c2.objectnumber AS child, 
    h3.name AS childcsid, 
    c2.id AS childid
FROM collectionobjects_common c1
JOIN collectionobjects_pahma cp1 ON (c1.id = cp1.id)
JOIN hierarchy h1 ON (c1.id = h1.id)
JOIN relations_common rc ON (h1.name=rc.subjectcsid AND rc.objectdocumenttype='CollectionObject')
JOIN hierarchy h2 ON (rc.objectcsid = h2.name)
JOIN collectionobjects_common c2 ON (h2.id = c2.id)
JOIN hierarchy h3 ON (c2.id = h3.id)
JOIN collectionobjects_pahma cp2 ON (c2.id = cp2.id)
WHERE cp2.iscomponent = 'yes' AND cp1.iscomponent = 'no' AND c1.objectnumber = '%s'""" % museumNumber
    
    objects.execute(getchildinfo)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

# ###############################

def getchildlocations(childcsid,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getchildlocations = """
   SELECT co.objectnumber, mc.locationdate, mc.reasonformove, 
CASE WHEN (mc.currentlocation IS NOT NULL AND mc.currentlocation <> '') THEN SUBSTRING(mc.currentlocation, POSITION(')''' IN mc.currentlocation)+2, LENGTH(mc.currentlocation)-POSITION(')''' IN mc.currentlocation)-2) END AS location
FROM collectionobjects_common co
JOIN hierarchy csid ON (co.id = csid.id)
JOIN relations_common r ON (csid.name = r.subjectcsid AND r.objectdocumenttype = 'Movement')
JOIN hierarchy h ON (r.objectcsid = h.name)
JOIN movements_common mc ON (h.id = mc.id)
WHERE csid.name  = '%s'
ORDER BY mc.locationdate DESC
LIMIT 1""" % childcsid
    
    objects.execute(getchildlocations)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

# ###############################

def getobjinfo(museumNumber,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getobjects = """
   SELECT co.objectnumber,
    co.collection,
    CASE WHEN (fc.item IS NOT NULL AND fc.item <> '') THEN SUBSTRING(fc.item, POSITION(')''' IN fc.item)+2, LENGTH(fc.item)-POSITION(')''' IN fc.item)-2) END AS collector,
    co.numberofobjects,
    co.distinguishingfeatures,
    co.recordstatus,
    n.objectname,
    ca.nagprainventoryname,
    bd.item,
    CASE WHEN (efc.item IS NOT NULL AND efc.item <> '') THEN SUBSTRING(efc.item, POSITION(')''' IN efc.item)+2, LENGTH(efc.item)-POSITION(')''' IN efc.item)-2) END AS filecode,
    cp.iscomponent,
    cp.pahmatmslegacydepartment,
    cp.pahmafieldlocverbatim,
    CASE WHEN (fcp.item IS NOT NULL AND fcp.item <> '') THEN SUBSTRING(fcp.item, POSITION(')''' IN fcp.item)+2, LENGTH(fcp.item)-POSITION(')''' IN fcp.item)-2) END AS site,
    cm.item,
    csid.name
FROM collectionobjects_common co
LEFT OUTER JOIN hierarchy h1 ON (co.id = h1.parentid AND h1.primarytype='objectNameGroup' AND h1.pos=0)
LEFT OUTER JOIN objectnamegroup n ON (n.id=h1.id)
LEFT OUTER JOIN collectionobjects_common_fieldcollectors fc ON (fc.id=co.id AND fc.pos=0)
LEFT OUTER JOIN collectionobjects_common_briefdescriptions bd ON (bd.id=co.id)
FULL OUTER JOIN collectionobjects_anthropology ca ON (ca.id=co.id)
LEFT OUTER JOIN collectionobjects_pahma_pahmaethnographicfilecodelist efc ON (co.id=efc.id AND efc.pos=0)
JOIN collectionobjects_pahma cp ON (co.id=cp.id)
LEFT OUTER JOIN collectionobjects_pahma_pahmafieldcollectionplacelist fcp ON (co.id=fcp.id AND fcp.pos=0)
LEFT OUTER JOIN collectionobjects_common_responsibledepartments cm ON (co.id=cm.id AND cm.pos=0)
FULL OUTER JOIN hierarchy csid ON (co.id=csid.id)
WHERE co.objectnumber = '%s'""" % museumNumber
    
    objects.execute(getobjects)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

# ###############################

def getaccinfo(museumNumber,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getaccobjects = """
   SELECT co.objectnumber, 
    ac.acquisitionreferencenumber,
    CASE WHEN (ao.item IS NOT NULL AND ao.item <> '') THEN SUBSTRING(ao.item, POSITION(')''' IN ao.item)+2, LENGTH(ao.item)-POSITION(')''' IN ao.item)-2) END AS donor,
    csid.name
FROM collectionobjects_common co
JOIN hierarchy h2 ON (co.id = h2.id)
JOIN relations_common rc ON (h2.name=rc.subjectcsid)
JOIN hierarchy h3 ON (rc.objectcsid=h3.name)
JOIN acquisitions_common ac ON (h3.id=ac.id)
JOIN acquisitions_common_owners ao ON (ac.id = ao.id AND ao.pos=0)
JOIN hierarchy csid ON (csid.id=ac.id)
WHERE co.objectnumber = '%s'""" % museumNumber
    
    objects.execute(getaccobjects)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

# ###############################

def getparentaccinfo(parentcsid,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getparentaccinfo = """
   SELECT ac.acquisitionreferencenumber,
    CASE WHEN (ao.item IS NOT NULL AND ao.item <> '') THEN SUBSTRING(ao.item, POSITION(')''' IN ao.item)+2, LENGTH(ao.item)-POSITION(')''' IN ao.item)-2) END AS donor,
    csid.name
FROM relations_common rc
JOIN hierarchy h1 ON (rc.objectcsid=h1.name)
JOIN acquisitions_common ac ON (h1.id=ac.id)
JOIN acquisitions_common_owners ao ON (ac.id = ao.id AND ao.pos=0)
JOIN hierarchy csid ON (csid.id=ac.id)
WHERE rc.subjectcsid = '%s'""" % parentcsid
    
    objects.execute(getparentaccinfo)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

# ###############################

def getaltnums(museumNumber,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getaltnums = """
   SELECT co.objectnumber,
    an.pahmaaltnum,
    an.pahmaaltnumtype,
    an.pahmaaltnumnote
FROM collectionobjects_common co
LEFT OUTER JOIN hierarchy h1 ON (co.id = h1.parentid AND h1.name='collectionobjects_pahma:pahmaAltNumGroupList')
JOIN pahmaaltnumgroup an ON (h1.id=an.id AND h1.pos=0)
WHERE co.objectnumber = '%s'""" % museumNumber
    
    objects.execute(getaltnums)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

# ###############################

def getallaltnums(museumNumber,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getallaltnums = """
   SELECT co.objectnumber,
    an.pahmaaltnum AS altnum,
    an.pahmaaltnumtype AS altnumtype,
    an.pahmaaltnumnote AS altnumnote
FROM collectionobjects_common co
LEFT OUTER JOIN hierarchy h1 ON (co.id = h1.parentid AND h1.name='collectionobjects_pahma:pahmaAltNumGroupList')
JOIN pahmaaltnumgroup an ON (h1.id=an.id AND h1.pos=0)
WHERE co.objectnumber = '%s'""" % museumNumber
    
    objects.execute(getallaltnums)
    #for object in objects.fetchall():
        #print object
    return objects.fetchall()

# ###############################

def getparentaltnums(parentid,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getparentaltnums = """
   SELECT co.objectnumber,
    an.pahmaaltnum,
    an.pahmaaltnumtype,
    an.pahmaaltnumnote
FROM collectionobjects_common co
LEFT OUTER JOIN hierarchy h1 ON (co.id = h1.parentid AND h1.name='collectionobjects_pahma:pahmaAltNumGroupList')
JOIN pahmaaltnumgroup an ON (h1.id=an.id AND h1.pos=0)
WHERE co.id = '%s'""" % parentid
    
    objects.execute(getparentaltnums)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

# ###############################

def getcultures(museumNumber,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getcultures = """
   SELECT co.objectnumber,
CASE WHEN (cg.assocpeople IS NOT NULL AND cg.assocpeople <> '') THEN SUBSTRING(cg.assocpeople, POSITION(')''' IN cg.assocpeople)+2, LENGTH(cg.assocpeople)-POSITION(')''' IN cg.assocpeople)-2) END AS culturalgroup,
    TRIM(cg.assocpeopletype), cg.assocpeoplenote
FROM collectionobjects_common co
FULL OUTER JOIN hierarchy h1 ON (co.id = h1.parentid AND h1.pos=0 AND h1.name='collectionobjects_common:assocPeopleGroupList')
FULL OUTER JOIN assocpeoplegroup cg ON (h1.id=cg.id)
WHERE co.objectnumber = '%s'""" % museumNumber
    
    objects.execute(getcultures)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

# ###############################

def getproddates(museumNumber,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getproddates = """
   SELECT co.objectnumber, sd.datedisplaydate, sd.dateassociation
FROM collectionobjects_common co
LEFT OUTER JOIN hierarchy h1 on (h1.parentid=co.id AND h1.name='collectionobjects_common:objectProductionDateGroupList' AND h1.pos=0)
LEFT OUTER JOIN structureddategroup sd on (h1.id=sd.id)
WHERE co.objectnumber = '%s'""" % museumNumber
    
    objects.execute(getproddates)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

# ###############################

def getmedia(museumNumber,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getmedia = """
   SELECT co.objectnumber, mc.blobcsid, mp.primarydisplay
FROM collectionobjects_common co
JOIN hierarchy h1 ON (co.id = h1.id)
JOIN relations_common rc ON (h1.name = rc.subjectcsid)
JOIN hierarchy h2 ON (rc.objectcsid = h2.name)
JOIN media_common mc ON (h2.id = mc.id)
JOIN media_pahma mp ON (mc.id = mp.id)
WHERE co.objectnumber = '%s'
ORDER BY mp.primarydisplay DESC""" % museumNumber
    
    objects.execute(getmedia)
    #for object in objects.fetchone():
        #print object
    return objects.fetchone()

#   #################################### Collection Stats web app #######################################

def getobjtypecounts(config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getobjtypecounts = """
    SELECT collection, COUNT(*) as howmanyobjects, SUM(co.numberofobjects) AS howmanypieces
    FROM collectionobjects_common co
    GROUP BY collection
    ORDER BY howmanyobjects DESC"""
    
    objects.execute(getobjtypecounts)
    for object in objects.fetchall():
        percentofobjects = str(round(100 * float(object[1])/float(701363),3)) + " %"
        percentofpieces = str(round(100 * float(object[2])/float(2233823),3)) + " %"

        #print str(object) + "<BR/>BANG"
        print """<tr>
        <td width="220" class="stattitle">""" +  str(object[0]) + """: </td>
        <td width="65px" class="statvalue">""" + str(locale.format("%d", int(object[1]), grouping=True)) + """ objects</td>
        <td width="50px">(""" + percentofobjects + """)</td>
        <td width="65px" class="statvalue">""" + str(locale.format("%d", int(object[2]), grouping=True)) + """ pieces</td>
        <td width="50px">(""" + percentofpieces + """)</td></tr>"""
    
        #return objects.fetchall()

# ###############################

def gettotalobjcount(config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    gettotalobjcount = """
    SELECT * FROM
    (SELECT COUNT(*) AS howmanymusnos
    FROM collectionobjects_common co
    JOIN collectionobjects_pahma cp ON (co.id=cp.id)
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted' AND cp.iscomponent = 'no') as howmanymusnos,
    
    (SELECT COUNT(*) AS howmanyobjects 
    FROM collectionobjects_common co
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted') as howmanyobjects,
    
    (SELECT SUM(co.numberofobjects) AS howmanypieces 
    FROM collectionobjects_common co
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted') as howmanypieces"""
    
    objects.execute(gettotalobjcount)
    return objects.fetchone()

# ###############################

def getlegacycatcounts(config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getlegacycatcounts = """
    SELECT cp.pahmatmslegacydepartment, COUNT(cp.pahmatmslegacydepartment) AS howmanyobjects, SUM(co.numberofobjects) AS howmanypieces
FROM collectionobjects_pahma cp
JOIN collectionobjects_common co ON (cp.id=co.id)
JOIN misc ON (misc.id = cp.id)
WHERE cp.pahmatmslegacydepartment IS NOT NULL AND cp.iscomponent != 'yes'
AND misc.lifecyclestate <> 'deleted'
GROUP BY pahmatmslegacydepartment

UNION

SELECT 'null' AS pahmatmslegacydepartment, (SELECT COUNT(*) FROM
collectionobjects_pahma cp, misc
	WHERE cp.pahmatmslegacydepartment IS NULL AND cp.iscomponent != 'yes'
	AND cp.id = misc.id AND misc.lifecyclestate <> 'deleted') AS howmanyobjects, 0 AS howmanypieces

ORDER BY howmanyobjects DESC"""
    
    objects.execute(getlegacycatcounts)
    for object in objects.fetchall():
        percentofobjects = str(round(100 * float(object[1])/float(701363),3)) + " %"
        percentofpieces = str(round(100 * float(object[2])/float(2233823),3)) + " %"
        
        print """<tr>
        <td width="220" class="stattitle">""" +  str(object[0]) + """: </td>
        <td width="65px" class="statvalue">""" + str(locale.format("%d", int(object[1]), grouping=True)) + """ objects</td>
        <td width="50px">(""" + percentofobjects + """)</td>
        <td width="65px" class="statvalue">""" + str(locale.format("%d", int(object[2]), grouping=True)) + """ pieces</td>
        <td width="50px">(""" + percentofpieces + """)</td></tr>"""

# ###############################

def getcollmanobjcount(config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getcollmanobjcount = """
    SELECT cm.item, COUNT(*) AS howmanyobjects, SUM(co.numberofobjects) AS howmanypieces
    FROM collectionobjects_common co
    JOIN collectionobjects_common_responsibledepartments cm ON (co.id=cm.id)
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted'
    GROUP BY cm.item
    ORDER BY howmanyobjects DESC"""
    
    objects.execute(getcollmanobjcount)
    for object in objects.fetchall():
        percentofobjects = str(round(100 * float(object[1])/float(701363),3)) + " %"
        percentofpieces = str(round(100 * float(object[2])/float(2233823),3)) + " %"
        
        print """<tr>
        <td width="220" class="stattitle">""" +  str(object[0]) + """: </td>
        <td width="65px" class="statvalue">""" + str(locale.format("%d", int(object[1]), grouping=True)) + """ objects</td>
        <td width="50px">(""" + percentofobjects + """)</td>
        <td width="65px" class="statvalue">""" + str(locale.format("%d", int(object[2]), grouping=True)) + """ pieces</td>
        <td width="50px">(""" + percentofpieces + """)</td></tr>"""

#   ######################################################################################################

def dbtransaction(command,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    cursor   = pahmadb.cursor()
    cursor.execute(command)

def setquery(type,location):

    if type == 'inventory':
	return  """
SELECT distinct on (locationkey,sortableobjectnumber,h3.name)
l.termdisplayName AS storageLocation,
concat(replace(l.termdisplayName,' ','0'),regexp_replace(ma.crate, '^.*\\)''(.*)''$', '\\1')) AS locationkey,
m.locationdate,
cc.objectnumber objectnumber,
cc.numberofobjects objectCount,
(case when ong.objectName is NULL then '' else ong.objectName end) objectName,
rc.subjectcsid movementCsid,
lc.refname movementRefname,
rc.objectcsid  objectCsid,
''  objectRefname,
m.id moveid,
rc.subjectdocumenttype,
rc.objectdocumenttype,
cp.sortableobjectnumber sortableobjectnumber,
ma.crate crateRefname,
regexp_replace(ma.crate, '^.*\\)''(.*)''$', '\\1') crate

FROM loctermgroup l

join hierarchy h1 on l.id = h1.id
join locations_common lc on lc.id = h1.parentid
join movements_common m on m.currentlocation = lc.refname


join hierarchy h2 on m.id = h2.id
join relations_common rc on rc.subjectcsid = h2.name
join movements_anthropology ma on ma.id = h2.id

join hierarchy h3 on rc.objectcsid = h3.name
join collectionobjects_common cc on h3.id = cc.id

left outer join hierarchy h5 on (cc.id = h5.parentid and h5.name =
'collectionobjects_common:objectNameList' and h5.pos=0)
left outer join objectnamegroup ong on (ong.id=h5.id)

left outer join collectionobjects_pahma cp on (cp.id=cc.id)

WHERE 
   l.termdisplayName = '""" + str(location) + """'
   
ORDER BY locationkey,sortableobjectnumber,h3.name desc
LIMIT 30000"""

    elif type == 'bedlist':
        return """
select 
case when (mc.currentlocation is not null and mc.currentlocation <> '')
     then regexp_replace(mc.currentlocation, '^.*\\)''(.*)''$', '\\1')
end as gardenlocation,
lct.termname shortgardenlocation,
case when (lc.locationtype is not null and lc.locationtype <> '')
     then regexp_replace(lc.locationtype, '^.*\\)''(.*)''$', '\\1')
end as locationtype,
co1.recordstatus,
co1.objectnumber, 
case when (tig.taxon is not null and tig.taxon <> '')
     then regexp_replace(tig.taxon, '^.*\\)''(.*)''$', '\\1')
end as Determination,
case when (tn.family is not null and tn.family <> '')
     then regexp_replace(tn.family, '^.*\\)''(.*)''$', '\\1')
end as family,
h1.name as objectcsid
from collectionobjects_common co1
left outer join hierarchy h1 on co1.id=h1.id
left outer join relations_common r1 on (h1.name=r1.subjectcsid and objectdocumenttype='Movement')
left outer join hierarchy h2 on (r1.objectcsid=h2.name and h2.isversion is not true)
left outer join movements_common mc on (mc.id=h2.id)
left outer join loctermgroup lct on (regexp_replace(mc.currentlocation, '^.*\\)''(.*)''$', '\\1')=lct.termdisplayname)
inner join misc misc1 on (mc.id=misc1.id and misc1.lifecyclestate <> 'deleted')

join collectionobjects_botgarden cob on (co1.id=cob.id)

left outer join hierarchy htig 
     on (co1.id = htig.parentid and htig.pos = 0 and htig.name = 'collectionobjects_naturalhistory:taxonomicIdentGroupList')
left outer join taxonomicIdentGroup tig on (tig.id = htig.id)

join collectionspace_core core on (core.id=co1.id and core.tenantid='35')
join misc misc2 on (misc2.id = co1.id and misc2.lifecyclestate <> 'deleted')

left outer join taxon_common tc on (tig.taxon=tc.refname)
left outer join taxon_naturalhistory tn on (tc.id=tn.id)

left outer join locations_common lc on (mc.currentlocation=lc.refname)

where deadflag='false' and regexp_replace(mc.currentlocation, '^.*\\)''(.*)''$', '\\1') = '%s'
   
ORDER BY gardenlocation,objectnumber
LIMIT 6000""" % location

#where deadflag='false' and mc.currentlocation='""" + str(location) + """'
# urn:cspace:botgarden.cspace.berkeley.edu:locationauthorities:name(location):item:name(garden96)''170A, Asian'''

    elif type == 'keyinfo' or type == 'barcodeprint':
	return """
SELECT distinct on (locationkey,sortableobjectnumber,h3.name)
l.termdisplayName AS storageLocation,
replace(l.termdisplayName,' ','0') AS locationkey,
m.locationdate,
cc.objectnumber objectnumber,
(case when ong.objectName is NULL then '' else ong.objectName end) objectName,
cc.numberofobjects objectCount,
case when (pfc.item is not null and pfc.item <> '') then
 substring(pfc.item, position(')''' IN pfc.item)+2, LENGTH(pfc.item)-position(')''' IN pfc.item)-2)
end AS fieldcollectionplace,
case when (apg.assocpeople is not null and apg.assocpeople <> '') then
 substring(apg.assocpeople, position(')''' IN apg.assocpeople)+2, LENGTH(apg.assocpeople)-position(')''' IN apg.assocpeople)-2)
end as culturalgroup,
rc.objectcsid  objectCsid,
case when (pef.item is not null and pef.item <> '') then
 substring(pef.item, position(')''' IN pef.item)+2, LENGTH(pef.item)-position(')''' IN pef.item)-2)
end as ethnographicfilecode,
pfc.item fcpRefName,
apg.assocpeople cgRefName,
pef.item efcRefName

FROM loctermgroup l

join hierarchy h1 on l.id = h1.id
join locations_common lc on lc.id = h1.parentid
join movements_common m on m.currentlocation = lc.refname

join hierarchy h2 on m.id = h2.id
join relations_common rc on rc.subjectcsid = h2.name

join hierarchy h3 on rc.objectcsid = h3.name
join collectionobjects_common cc on h3.id = cc.id

left outer join hierarchy h4 on (cc.id = h4.parentid and h4.name =
'collectionobjects_common:objectNameList' and (h4.pos=0 or h4.pos is null))
left outer join objectnamegroup ong on (ong.id=h4.id)

left outer join collectionobjects_pahma cp on (cp.id=cc.id)
left outer join collectionobjects_pahma_pahmafieldcollectionplacelist pfc on (pfc.id=cc.id)
left outer join collectionobjects_pahma_pahmaethnographicfilecodelist pef on (pef.id=cc.id)

left outer join hierarchy h5 on (cc.id=h5.parentid and h5.primarytype =
'assocPeopleGroup' and (h5.pos=0 or h5.pos is null))
left outer join assocpeoplegroup apg on (apg.id=h5.id)

WHERE 
   l.termdisplayName = '""" + str(location) + """'
   
AND (pfc.pos=0 or pfc.pos is null)
AND (h5.pos=0 or h5.pos is null)
AND (pef.pos=0 or pef.pos is null)
   
ORDER BY locationkey,sortableobjectnumber,h3.name desc
LIMIT 30000
"""

def getlocations(location1,location2,num2ret,config,updateType):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)
   
    debug = False
 
    result = []

    for loc in getloclist('set',location1,'',num2ret,config):
        getobjects = setquery(updateType,loc[0])

        try:
	    elapsedtime = time.time()
            objects.execute(getobjects)
	    elapsedtime = time.time() - elapsedtime
            if debug: sys.stderr.write('all objects: %s :: %s\n' % (loc[0],elapsedtime))
	except pgdb.DatabaseError, e:
            sys.stderr.write('getlocations select error: %s' % e)
            return result       
        except:
	    sys.stderr.write("some other getlocations database error!")
            return result       

        # a hack: check each object to make it is really in this location
	try:
	    rows = objects.fetchall()
	except pgdb.DatabaseError, e:
            sys.stderr.write("fetchall getlocations database error!")

        if debug: sys.stderr.write('number objects to be checked: %s\n' % len(rows))
        try:
            # a hack: check each object to make it is really in this location
            for row in rows:
	        elapsedtime = time.time()
	        cf = findcurrentlocation(row[8],config)
	        elapsedtime = time.time() - elapsedtime
                if debug: sys.stderr.write('currentlocation: %s :: %s\n' % (row[8],elapsedtime))
                if debug: sys.stderr.write('checking csid %s %s %s\n' % (row[8],cf,row[0]))
	        if cf  == row[0]:
	        #if findcurrentlocation(row[8]) == row[0]:
    	            result.append(row)
	        elif cf  == 'findcurrentlocation error':
    	            result.append(row)
                    sys.stderr.write('%s : %s (%s)\n' % (row[8],cf,str(loc[0])))
	        elif str(loc[0]) in str(cf):
		    row[0] = cf
    	            result.append(row)
                    if debug: sys.stderr.write('%s found at (%s) : but in a "crate": %s' % (row[8],str(loc[0]),cf))
	        else:
		    #print 'not here',row
                    if debug: sys.stderr.write('%s not here (%s) : found at %s\n' % (row[8],str(loc[0]),cf))
    	            #result.append(row)
		    pass
	except:
           raise
           sys.stderr.write("other getobjects error: %s" % len(rows))

    return result

def getplants(location1,location2,num2ret,config,updateType):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    debug = False

    result = []

    for loc in getloclist('set',location1,'',num2ret,config):
        getobjects = setquery(updateType,loc[0])

        try:
            elapsedtime = time.time()
            objects.execute(getobjects)
            elapsedtime = time.time() - elapsedtime
            if debug: sys.stderr.write('all objects: %s :: %s\n' % (loc[0],elapsedtime))
        except pgdb.DatabaseError, e:
            sys.stderr.write('getlocations select error: %s' % e)
            return result
        except:
            sys.stderr.write("some other getlocations database error!")
            return result

        # a hack: check each object to make it is really in this location
        try:
            result = objects.fetchall()
        except pgdb.DatabaseError, e:
            sys.stderr.write("fetchall getlocations database error!")

        return result

def getloclist(searchType,location1,location2,num2ret,config):

    # 'set' means 'next num2ret locations', otherwise prefix match
    if searchType == 'set':
	whereclause = "WHERE locationkey >= replace('" + location1 + "',' ','0')"
    elif searchType == 'prefix':
	whereclause = "WHERE locationkey LIKE replace('" + location1 + "%',' ','0')"
    elif searchType == 'range':
	whereclause = "WHERE locationkey >= replace('" + location1 + "',' ','0') AND locationkey <= replace('" + location2 + "',' ','0')"

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)
    if int(num2ret) > 30000: num2ret = 30000
    if int(num2ret) < 1:    num2ret = 1

    getobjects = """
select * from (
select termdisplayname,replace(termdisplayname,' ','0') locationkey from loctermgroup) as t
""" + whereclause + """
order by locationkey
limit """ + str(num2ret)
    
    objects.execute(getobjects)
    #for object in objects.fetchall():
        #print object
    return objects.fetchall()

def findcurrentlocation(csid,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getloc = "select findcurrentlocation('" + csid + "')"
   
    try: 
        objects.execute(getloc)
    except:
	return "findcurrentlocation error"

    return objects.fetchone()[0]

def getrefname(table,term,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    if term == None or term == '':
	return ''

    query = "select refname from %s where refname ILIKE '%%''%s''%%' LIMIT 1" % (table,term)

    try:
        objects.execute(query)
        return objects.fetchone()[0]
    except:
	return ''
        raise


def findrefnames(table,termlist,config):

    pahmadb  = pgdb.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    result = []
    for t in termlist:
        query = "select refname from %s where refname ILIKE '%%''%s''%%'" % (table,t)

        try:
            objects.execute(query)
	    refname = objects.fetchone()
	    result.append([t,refname])
        except:
	    raise
            return "findrefnames error"

    return result


if __name__ == "__main__":

    from cswaUtils import getConfig
    config = getConfig('sysinvProd.cfg')
    print '\nrefnames\n'
    print getrefname('concepts_common','zzz',config)
    print getrefname('concepts_common','',config)
    print getrefname('concepts_common','Yurok',config)
    print findrefnames('places_common',['zzz','Sudan, Northern Africa, Africa'],config)
    print '\ncurrentlocation\n'
    print findcurrentlocation('c65b2ffa-6e5f-4a6d-afa4-e0b57fc16106',config)

    print '\nset of locations\n'
    for loc in getloclist('set','Kroeber, 20A, W B','',10,config):
        print loc

    print '\nlocations by prefix\n'
    for loc in getloclist('prefix','Kroeber, 20A, W B','',1000,config):
        print loc

    print '\nlocations by range\n'
    for loc in getloclist('range','Kroeber, 20A, W B2, 1','Kroeber, 20A, W B5, 11',1000,config):
        print loc

    print '\nobjects\n'
    #for loc in getlocations('no location entered',1):
    #for i,loc in enumerate(getlocations('Regatta, A150, Cat. 3 cabinet  1 A,  4',1,config)):
    #for i,loc in enumerate(getlocations('Kroeber, 20A, W 23,  9',1,config,'inventory')):
    #for i,loc in enumerate(getlocations('Regatta, A150, RiveTier 27, C',1,config,'inventory')):
    #for i,loc in enumerate(getlocations('Kroeber, 20AMez, 128 A','',1,config,'inventory')):
    for i,loc in enumerate(getlocations('Regatta, A150, South Nexel Unit 6, C','',1,config,'inventory')):
	print 'location',i+1,loc[0:6]

    print '\nkeyinfo\n'
    for i,loc in enumerate(getlocations('Kroeber, 20AMez, 128 A','',1,config,'keyinfo')):
	print 'location',i+1,loc[0:12]
