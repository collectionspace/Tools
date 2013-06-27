#!/usr/bin/env /usr/bin/python

import time
import sys
import cgi
import pgdb

timeoutcommand = 'set statement_timeout to 300000'


def testDB(config):
    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    try:
        objects.execute('set statement_timeout to 5000')
        objects.execute('select * from hierarchy limit 30000')
        return "OK"
    except pgdb.DatabaseError, e:
        sys.stderr.write('testDB error: %s' % e)
        return  '%s' % e
    except:
        sys.stderr.write("some other testDB error!")
        return "Some other failure"

    
def dbtransaction(command, config):
    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    cursor = dbconn.cursor()
    cursor.execute(command)


def setquery(type, location):
    if type == 'inventory':
        return """
SELECT distinct on (locationkey,sortableobjectnumber,h3.name)
(case when ca.computedcrate is Null then l.termdisplayName  
     else concat(l.termdisplayName,
     ': ',regexp_replace(ca.computedcrate, '^.*\\)''(.*)''$', '\\1')) end) AS storageLocation,
replace(concat(l.termdisplayName,
     ': ',regexp_replace(ca.computedcrate, '^.*\\)''(.*)''$', '\\1')),' ','0') AS locationkey,
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
join collectionobjects_common cc on (h3.id = cc.id and cc.computedcurrentlocation = lc.refname)

left outer join collectionobjects_anthropology ca on (ca.id=cc.id)
left outer join hierarchy h5 on (cc.id = h5.parentid and h5.name =
'collectionobjects_common:objectNameList' and h5.pos=0)
left outer join objectnamegroup ong on (ong.id=h5.id)

left outer join collectionobjects_pahma cp on (cp.id=cc.id)

join misc ms on (cc.id=ms.id and ms.lifecyclestate <> 'deleted')

WHERE 
   l.termdisplayName = '""" + str(location) + """'
   
ORDER BY locationkey,sortableobjectnumber,h3.name desc
LIMIT 30000"""

    elif type == 'bedlist' or type == 'locreport':

        if type == 'bedlist':
            sortkey = 'gardenlocation'
            searchkey = 'mc.currentlocation'
        elif type == 'locreport':
            sortkey = 'determination'
            searchkey = 'tig.taxon'

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
findhybridaffinname(tig.id) as determination,
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

where regexp_replace(%s, '^.*\\)''(.*)''$', '\\1') = '%s'
   
ORDER BY %s,to_number(objectnumber,'9999.9999')
LIMIT 6000""" % (searchkey, location, sortkey)

    elif type == 'keyinfo' or type == 'barcodeprint' or type == 'packinglist':
        return """
SELECT distinct on (locationkey,sortableobjectnumber,h3.name)
(case when ca.computedcrate is Null then l.termdisplayName  
     else concat(l.termdisplayName,
     ': ',regexp_replace(ca.computedcrate, '^.*\\)''(.*)''$', '\\1')) end) AS storageLocation,
replace(concat(l.termdisplayName,
     ': ',regexp_replace(ca.computedcrate, '^.*\\)''(.*)''$', '\\1')),' ','0') AS locationkey,
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
pef.item efcRefName,
ca.computedcrate

FROM loctermgroup l

join hierarchy h1 on l.id = h1.id
join locations_common lc on lc.id = h1.parentid
join movements_common m on m.currentlocation = lc.refname

join hierarchy h2 on m.id = h2.id
join relations_common rc on rc.subjectcsid = h2.name

join hierarchy h3 on rc.objectcsid = h3.name
join collectionobjects_common cc on (h3.id = cc.id and cc.computedcurrentlocation = lc.refname)

left outer join hierarchy h4 on (cc.id = h4.parentid and h4.name =
'collectionobjects_common:objectNameList' and (h4.pos=0 or h4.pos is null))
left outer join objectnamegroup ong on (ong.id=h4.id)

left outer join collectionobjects_anthropology ca on (ca.id=cc.id)
left outer join collectionobjects_pahma cp on (cp.id=cc.id)
left outer join collectionobjects_pahma_pahmafieldcollectionplacelist pfc on (pfc.id=cc.id and pfc.pos=0)
left outer join collectionobjects_pahma_pahmaethnographicfilecodelist pef on (pef.id=cc.id and pef.pos=0)

left outer join hierarchy h5 on (cc.id=h5.parentid and h5.primarytype =
'assocPeopleGroup' and (h5.pos=0 or h5.pos is null))
left outer join assocpeoplegroup apg on (apg.id=h5.id)

join misc ms on (cc.id=ms.id and ms.lifecyclestate <> 'deleted')

WHERE 
   l.termdisplayName = '""" + str(location) + """'
   
AND (pfc.pos=0 or pfc.pos is null)
AND (h5.pos=0 or h5.pos is null)
AND (pef.pos=0 or pef.pos is null)
   
ORDER BY locationkey,sortableobjectnumber,h3.name desc
LIMIT 30000
"""

    elif type == 'getalltaxa':
        return """
select co1.objectnumber,
findhybridaffinname(tig.id) as determination,
case when (tn.family is not null and tn.family <> '')
     then regexp_replace(tn.family, '^.*\\)''(.*)''$', '\\1')
end as family,
case when (mc.currentlocation is not null and mc.currentlocation <> '')
     then regexp_replace(mc.currentlocation, '^.*\\)''(.*)''$', '\\1')
end as gardenlocation,
co1.recordstatus dataQuality,
case when (lg.fieldlocplace is not null and lg.fieldlocplace <> '') then regexp_replace(lg.fieldlocplace, '^.*\\)''(.*)''$', '\\1')
     when (lg.fieldlocplace is null and lg.taxonomicrange is not null) then 'Geographic range: '||lg.taxonomicrange
end as locality,
htig.parentid as objectcsid,
con.rare,
cob.deadflag,
regexp_replace(tig2.taxon, '^.*\\)''(.*)''$', '\\1') as determinationNoAuth

from collectionobjects_common co1

join hierarchy h1 on co1.id=h1.id
join relations_common r1 on (h1.name=r1.subjectcsid and objectdocumenttype='Movement')
join hierarchy h2 on (r1.objectcsid=h2.name and h2.isversion is not true)
join movements_common mc on (mc.id=h2.id)

join collectionobjects_naturalhistory con on (co1.id = con.id %s)
join collectionobjects_botgarden cob on (co1.id=cob.id %s)

left outer join hierarchy htig
     on (co1.id = htig.parentid and htig.pos = 0 and htig.name = 'collectionobjects_naturalhistory:taxonomicIdentGroupList')
left outer join taxonomicIdentGroup tig on (tig.id = htig.id)

left outer join hierarchy htig2
     on (co1.id = htig2.parentid and htig2.pos = 1 and htig2.name = 'collectionobjects_naturalhistory:taxonomicIdentGroupList')
left outer join taxonomicIdentGroup tig2 on (tig2.id = htig2.id)

left outer join hierarchy hlg
     on (co1.id = hlg.parentid and hlg.pos = 0 and hlg.name='collectionobjects_naturalhistory:localityGroupList')
left outer join localitygroup lg on (lg.id = hlg.id)

join collectionspace_core core on (core.id=co1.id and core.tenantid=35)
join misc misc2 on (misc2.id = co1.id and misc2.lifecyclestate <> 'deleted') -- object not deleted

left outer join taxon_common tc on (tig.taxon=tc.refname)
left outer join taxon_naturalhistory tn on (tc.id=tn.id) order by determination""" % ('', '')

#left outer join taxon_naturalhistory tn on (tc.id=tn.id)""" % ("and con.rare = 'true'","and cob.deadflag = 'false'")

def getlocations(location1, location2, num2ret, config, updateType):
    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)

    debug = False

    result = []

    for loc in getloclist('set', location1, '', num2ret, config):
        getobjects = setquery(updateType, loc[0])

        try:
            elapsedtime = time.time()
            objects.execute(getobjects)
            elapsedtime = time.time() - elapsedtime
            if debug: sys.stderr.write('all objects: %s :: %s\n' % (loc[0], elapsedtime))
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
            for row in rows:
                result.append(row)
        except:
            raise
            sys.stderr.write("other getobjects error: %s" % len(rows))

    return result


def getplants(location1, location2, num2ret, config, updateType):
    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)

    debug = False

    result = []

    #for loc in getloclist('set',location1,'',num2ret,config):
    getobjects = setquery(updateType, location1)
    #print getobjects
    try:
        elapsedtime = time.time()
        objects.execute(getobjects)
        elapsedtime = time.time() - elapsedtime
        #sys.stderr.write('query :: %s\n' % getobjects)
        if debug: sys.stderr.write('all objects: %s :: %s\n' % (location1, elapsedtime))
    except pgdb.DatabaseError, e:
        raise
        sys.stderr.write('getplants select error: %s' % e)
        return result
    except:
        sys.stderr.write("some other getplants database error!")
        return result

    # a hack: check each object to make it is really in this location
    try:
        result = objects.fetchall()
        if debug: sys.stderr.write('object count: %s\n' % (len(result)))
    except pgdb.DatabaseError, e:
        sys.stderr.write("fetchall getplants database error!")

    return result

    
def getloclist(searchType, location1, location2, num2ret, config):
    # 'set' means 'next num2ret locations', otherwise prefix match
    if searchType == 'set':
        whereclause = "WHERE locationkey >= replace('" + location1 + "',' ','0')"
    elif searchType == 'prefix':
        whereclause = "WHERE locationkey LIKE replace('" + location1 + "%',' ','0')"
    elif searchType == 'range':
        whereclause = "WHERE locationkey >= replace('" + location1 + "',' ','0') AND locationkey <= replace('" + location2 + "',' ','0')"

    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)
    if int(num2ret) > 30000: num2ret = 30000
    if int(num2ret) < 1:    num2ret = 1

    getobjects = """
select * from (
select termdisplayname,replace(termdisplayname,' ','0') locationkey 
FROM loctermgroup ltg
INNER JOIN hierarchy h_ltg
        ON h_ltg.id=ltg.id
INNER JOIN hierarchy h_loc
        ON h_loc.id=h_ltg.parentid
INNER JOIN misc
        ON misc.id=h_loc.id and misc.lifecyclestate <> 'deleted'
) as t
""" + whereclause + """
order by locationkey
limit """ + str(num2ret)

    objects.execute(getobjects)
    #for object in objects.fetchall():
    #print object
    return objects.fetchall()

def getobjlist(searchType, object1, object2, num2ret, config):
    query1 = """
    SELECT objectNumber,
cp.sortableobjectnumber
FROM collectionobjects_common cc
left outer join collectionobjects_pahma cp on (cp.id=cc.id)
INNER JOIN hierarchy h1
        ON cc.id=h1.id
INNER JOIN misc
        ON misc.id=h1.id and misc.lifecyclestate <> 'deleted'
WHERE
     cc.objectNumber = '%s'"""
    
    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)
    if int(num2ret) > 1000: num2ret = 1000
    if int(num2ret) < 1:    num2ret = 1

    objects.execute(query1 % object1)
    (object1,sortkey1) = objects.fetchone()
    objects.execute(query1 % object2)
    (object2,sortkey2) = objects.fetchone()
    
    # 'set' means 'next num2ret objects', otherwise prefix match
    if searchType == 'set':
        whereclause = "WHERE sortableobjectnumber >= '" + sortkey1 + "'"
    elif searchType == 'prefix':
        whereclause = "WHERE sortableobjectnumber LIKE '" + sortkey1 + "%'"
    elif searchType == 'range':
        whereclause = "WHERE sortableobjectnumber >= '" + sortkey1 + "' AND sortableobjectnumber <= '" + sortkey2 + "'"

    getobjects = """SELECT DISTINCT ON (sortableobjectnumber)
(case when ca.computedcrate is Null then regexp_replace(cc.computedcurrentlocation, '^.*\\)''(.*)''$', '\\1') 
     else concat(regexp_replace(cc.computedcurrentlocation, '^.*\\)''(.*)''$', '\\1'),
     ': ',regexp_replace(ca.computedcrate, '^.*\\)''(.*)''$', '\\1')) end) AS storageLocation,
cc.computedcurrentlocation AS locrefname,
'' AS locdate,
cc.objectnumber objectnumber,
(case when ong.objectName is NULL then '' else ong.objectName end) objectName,
cc.numberofobjects objectCount,
case when (pfc.item is not null and pfc.item <> '') then
 substring(pfc.item, position(')''' IN pfc.item)+2, LENGTH(pfc.item)-position(')''' IN pfc.item)-2)
end AS fieldcollectionplace,
case when (apg.assocpeople is not null and apg.assocpeople <> '') then
 substring(apg.assocpeople, position(')''' IN apg.assocpeople)+2, LENGTH(apg.assocpeople)-position(')''' IN apg.assocpeople)-2)
end as culturalgroup,
h1.name  objectCsid,
case when (pef.item is not null and pef.item <> '') then
 substring(pef.item, position(')''' IN pef.item)+2, LENGTH(pef.item)-position(')''' IN pef.item)-2)
end as ethnographicfilecode,
pfc.item fcpRefName,
apg.assocpeople cgRefName,
pef.item efcRefName,
ca.computedcrate crateRefname,
regexp_replace(ca.computedcrate, '^.*\\)''(.*)''$', '\\1') crate

FROM collectionobjects_pahma cp
left outer join collectionobjects_common cc on (cp.id=cc.id)

left outer join hierarchy h1 on (cp.id = h1.id)

left outer join hierarchy h4 on (cc.id = h4.parentid and h4.name =
'collectionobjects_common:objectNameList' and (h4.pos=0 or h4.pos is null))
left outer join objectnamegroup ong on (ong.id=h4.id)

left outer join collectionobjects_anthropology ca on (ca.id=cc.id)
left outer join collectionobjects_pahma_pahmafieldcollectionplacelist pfc on (pfc.id=cc.id and pfc.pos=0)
left outer join collectionobjects_pahma_pahmaethnographicfilecodelist pef on (pef.id=cc.id and pef.pos=0)

left outer join hierarchy h5 on (cc.id=h5.parentid and h5.primarytype =
'assocPeopleGroup' and (h5.pos=0 or h5.pos is null))
left outer join assocpeoplegroup apg on (apg.id=h5.id)

join misc ms on (cc.id=ms.id and ms.lifecyclestate <> 'deleted')

""" + whereclause + """
ORDER BY sortableobjectnumber
limit """ + str(num2ret)

    objects.execute(getobjects)
    #for object in objects.fetchall():
    #print object
    return objects.fetchall()


def findcurrentlocation(csid, config):
    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)

    getloc = "select findcurrentlocation('" + csid + "')"

    try:
        objects.execute(getloc)
    except:
        return "findcurrentlocation error"

    return objects.fetchone()[0]


def getrefname(table, term, config):
    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)

    if term == None or term == '':
        return ''

    query = "select refname from %s where refname ILIKE '%%''%s''%%' LIMIT 1" % (table, term.replace("'","''"))

    try:
        objects.execute(query)
        return objects.fetchone()[0]
    except:
        return ''
        raise


def findrefnames(table, termlist, config):
    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)

    result = []
    for t in termlist:
        query = "select refname from %s where refname ILIKE '%%''%s''%%'" % (table, t.replace("'","''"))

        try:
            objects.execute(query)
            refname = objects.fetchone()
            result.append([t, refname])
        except:
            raise
            return "findrefnames error"

    return result


def findparents(refname, config):
    dbconn = pgdb.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)
    query = """WITH RECURSIVE ethnculture_hierarchyquery as (
SELECT regexp_replace(cc.refname, '^.*\\)''(.*)''$', '\\1') AS ethnCulture,
      cc.refname,
      rc.objectcsid broaderculturecsid,
      regexp_replace(cc2.refname, '^.*\\)''(.*)''$', '\\1') AS ethnCultureBroader,
      0 AS level
FROM concepts_common cc
JOIN hierarchy h ON (cc.id = h.id)
LEFT OUTER JOIN relations_common rc ON (h.name = rc.subjectcsid)
LEFT OUTER JOIN hierarchy h2 ON (rc.relationshiptype='hasBroader' AND rc.objectcsid = h2.name)
LEFT OUTER JOIN concepts_common cc2 ON (cc2.id = h2.id)
WHERE cc.refname LIKE 'urn:cspace:pahma.cspace.berkeley.edu:conceptauthorities:name(concept)%%'
and cc.refname = '%s'
UNION ALL
SELECT regexp_replace(cc.refname, '^.*\\)''(.*)''$', '\\1') AS ethnCulture,
      cc.refname,
      rc.objectcsid broaderculturecsid,
      regexp_replace(cc2.refname, '^.*\\)''(.*)''$', '\\1') AS ethnCultureBroader,
      ech.level-1 AS level
FROM concepts_common cc
JOIN hierarchy h ON (cc.id = h.id)
LEFT OUTER JOIN relations_common rc ON (h.name = rc.subjectcsid)
LEFT OUTER JOIN hierarchy h2 ON (rc.relationshiptype='hasBroader' AND rc.objectcsid = h2.name)
LEFT OUTER JOIN concepts_common cc2 ON (cc2.id = h2.id)
INNER JOIN ethnculture_hierarchyquery AS ech ON h.name = ech.broaderculturecsid)
SELECT ethnCulture, refname, level
FROM ethnculture_hierarchyquery
order by level""" % refname.replace("'","''")
    
    try:
        objects.execute(query)
        return objects.fetchall()
    except:
        #raise
        return [["findparents error"]]
        
if __name__ == "__main__":

    from cswaUtils import getConfig

    config = getConfig('ucbgLocationReport.cfg')
    print getplants('Velleia rosea', '', 1, config, 'locreport')
    sys.exit()

    config = getConfig('sysinvProd.cfg')
    print '\nrefnames\n'
    print getrefname('concepts_common', 'zzz', config)
    print getrefname('concepts_common', '', config)
    print getrefname('concepts_common', 'Yurok', config)
    print findrefnames('places_common', ['zzz', 'Sudan, Northern Africa, Africa'], config)
    print '\ncurrentlocation\n'
    print findcurrentlocation('c65b2ffa-6e5f-4a6d-afa4-e0b57fc16106', config)

    print '\nset of locations\n'
    for loc in getloclist('set', 'Kroeber, 20A, W B', '', 10, config):
        print loc

    print '\nlocations by prefix\n'
    for loc in getloclist('prefix', 'Kroeber, 20A, W B', '', 1000, config):
        print loc

    print '\nlocations by range\n'
    for loc in getloclist('range', 'Kroeber, 20A, W B2, 1', 'Kroeber, 20A, W B5, 11', 1000, config):
        print loc

    print '\nobjects\n'
    #for loc in getlocations('no location entered',1):
    #for i,loc in enumerate(getlocations('Regatta, A150, Cat. 3 cabinet  1 A,  4',1,config)):
    #for i,loc in enumerate(getlocations('Kroeber, 20A, W 23,  9',1,config,'inventory')):
    #for i,loc in enumerate(getlocations('Regatta, A150, RiveTier 27, C',1,config,'inventory')):
    #for i,loc in enumerate(getlocations('Kroeber, 20AMez, 128 A','',1,config,'inventory')):
    for i, loc in enumerate(getlocations('Regatta, A150, South Nexel Unit 6, C', '', 1, config, 'inventory')):
        print 'location', i + 1, loc[0:6]

    print '\nkeyinfo\n'
    for i, loc in enumerate(getlocations('Kroeber, 20AMez, 128 A', '', 1, config, 'keyinfo')):
        print 'location', i + 1, loc[0:12]
