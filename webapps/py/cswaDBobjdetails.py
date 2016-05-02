#!/usr/bin/env /usr/bin/python

import time
import sys
import cgi
import psycopg2
import locale

locale.setlocale(locale.LC_ALL, 'en_US')

timeoutcommand = 'set statement_timeout to 300000'

# ###############################

def getparentinfo(museumNumber, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
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

def getchildinfo(museumNumber, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
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

def getchildlocations(childcsid, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
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

def getobjinfo(museumNumber, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
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
    csid.name,
    co.id,
    regexp_replace(co.computedcurrentlocation, '^.*\\)''(.*)''$', '\\1'),
    co.computedcurrentlocation
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

def getaccinfo(objectcsid, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getaccobjects = """
   SELECT ac.acquisitionreferencenumber,
    CASE WHEN (ao.item IS NOT NULL AND ao.item <> '') THEN SUBSTRING(ao.item, POSITION(')''' IN ao.item)+2, LENGTH(ao.item)-POSITION(')''' IN ao.item)-2) END AS donor,
    csid.name
FROM relations_common rc
JOIN hierarchy h3 ON (rc.objectcsid=h3.name)
JOIN acquisitions_common ac ON (h3.id=ac.id)
JOIN acquisitions_common_owners ao ON (ac.id = ao.id AND ao.pos=0)
JOIN hierarchy csid ON (csid.id=ac.id)
WHERE rc.subjectcsid = '%s'""" % objectcsid

    objects.execute(getaccobjects)
    #for object in objects.fetchone():
    #print object
    return objects.fetchone()

# ###############################

def getparentaccinfo(parentcsid, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
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

def getaltnums(objectid, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getaltnums = """
   SELECT an.pahmaaltnum,
    an.pahmaaltnumtype,
    an.pahmaaltnumnote
FROM hierarchy h1
JOIN pahmaaltnumgroup an ON (h1.id=an.id AND h1.pos=0)
WHERE h1.name='collectionobjects_pahma:pahmaAltNumGroupList'
AND h1.parentid = '%s'""" % objectid

    objects.execute(getaltnums)
    #for object in objects.fetchone():
    #print object
    return objects.fetchone()

# ###############################

def getallaltnums(museumNumber, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
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

def getparentaltnums(parentid, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
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

def getassoccultures(objectid, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getassoccultures = """
   SELECT CASE WHEN (cg.assocpeople IS NOT NULL AND cg.assocpeople <> '') THEN SUBSTRING(cg.assocpeople, POSITION(')''' IN cg.assocpeople)+2, LENGTH(cg.assocpeople)-POSITION(')''' IN cg.assocpeople)-2) END AS culturalgroup,
    cg.assocpeopletype, cg.assocpeoplenote
FROM hierarchy h1
FULL OUTER JOIN assocpeoplegroup cg ON (h1.id=cg.id)
WHERE h1.name='collectionobjects_common:assocPeopleGroupList'
AND h1.parentid = '%s'
ORDER BY h1.pos""" % objectid

    objects.execute(getassoccultures)
    return objects.fetchall()

# ###############################

def getproddates(museumNumber, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
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

def getmedia(museumNumber, config):
    pahmadb = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getmedia = """
   SELECT co.objectnumber, mc.blobcsid, mp.primarydisplay, mp.approvedforweb, mc.description
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
    return objects.fetchall()
