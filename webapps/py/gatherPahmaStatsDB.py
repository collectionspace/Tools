#!/usr/bin/env /usr/bin/python

import time
import sys
import cgi
import psycopg2
import locale

import gatherPahmaStats

locale.setlocale(locale.LC_ALL, 'en_US')

timeoutcommand = 'set statement_timeout to 1200000'

# ############## Megaquery: Overall counts: all Museum number, object and piece counts ######################

def gettotalobjcount(config):
    timepoint0 = time.time()

    pahmadb  = psycopg2.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    #sys.exit()

    g = []

    totalmuseumnumbercount = """
    SELECT COUNT(*) AS totalMusNoCount
    FROM collectionobjects_common co
    JOIN collectionobjects_pahma cp ON (co.id=cp.id)
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted' AND cp.iscomponent = 'no'"""

    totalobjectcount = """
    SELECT COUNT(*) AS totalObjectCount
    FROM collectionobjects_common co
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted'"""

    objectovercount = """
    SELECT COUNT(objectOverCount.numberofobjects) AS objectOverCount
    FROM (
    SELECT DISTINCT co.objectnumber, co.numberofobjects
    FROM collectionobjects_common co
    JOIN hierarchy h1 ON (co.id = h1.id)
    JOIN relations_common rc ON (h1.name = rc.objectcsid AND rc.subjectdocumenttype='CollectionObject' AND rc.relationshiptype='hasBroader')
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted'
    ) AS objectOverCount"""

    totalpiececount = """
    SELECT SUM(co.numberofobjects) AS totalPieceCount
    FROM collectionobjects_common co
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted'"""

    pieceovercount = """
    SELECT SUM(pieceOverCount.numberofobjects) AS pieceOverCount
    FROM (
    SELECT DISTINCT co.objectnumber, co.numberofobjects
    FROM collectionobjects_common co
    JOIN hierarchy h1 ON (co.id = h1.id)
    JOIN relations_common rc ON (h1.name = rc.objectcsid AND rc.subjectdocumenttype='CollectionObject' AND rc.relationshiptype='hasBroader')
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted') AS pieceOverCount"""
    
    objects.execute(totalmuseumnumbercount)
    result1 = objects.fetchone()
    g.append(result1)
    
    objects.execute(totalobjectcount)
    result2 = objects.fetchone()
    g.append(result2)
    
    objects.execute(objectovercount)
    result3 = objects.fetchone()
    g.append(result3)
    
    objects.execute(totalpiececount)
    result4 = objects.fetchone()
    g.append(result4)
    
    objects.execute(pieceovercount)
    result5 = objects.fetchone()
    g.append(result5)

    return g

# ################# Abstracted query to get counts of groups of objects #####################

def getgroupedobjcounts(additionaljoin1, additionaljoin2, additionalwhere, fieldalias, field, config):
    timepoint0 = time.time()
    
    pahmadb  = psycopg2.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    selectedfield = str(field) + " AS " + str(fieldalias)

    getmuseumnumbercounts = """
    SELECT %s, COUNT(*) AS totalMusNoCount, NULL::INTEGER AS totalObjectCount, NULL::INTEGER AS trueObjectCount, NULL::INTEGER AS totalPieceCount, NULL::INTEGER AS truePieceCount
    FROM collectionobjects_common co
    %s
    JOIN collectionobjects_pahma cp ON (co.id=cp.id)
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted' AND cp.iscomponent = 'no'
    %s
    GROUP BY %s
    ORDER BY %s
    """ % (str(selectedfield), str(additionaljoin1), str(additionalwhere), str(fieldalias), str(fieldalias))

    getobjectpiecetotalcounts = """
    SELECT %s, NULL::INTEGER AS totalMusNoCount, COUNT(*) AS totalObjectCount, NULL::INTEGER AS trueObjectCount, SUM(co.numberofobjects) AS totalPieceCount, NULL::INTEGER AS truePieceCount
    FROM collectionobjects_common co
    %s
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted'
    %s
    GROUP BY %s
    ORDER BY %s
    """ % (str(selectedfield), str(additionaljoin2), str(additionalwhere), str(fieldalias), str(fieldalias))
    
    getobjectpiecetruecounts = """
    SELECT %s, NULL::INTEGER AS totalMusNoCount, NULL::INTEGER AS totalObjectCount, COUNT(*) AS trueObjectCount, NULL::INTEGER AS totalPieceCount, SUM(co.numberofobjects) AS truePieceCount
    FROM collectionobjects_common co
    %s
    JOIN misc ON (co.id=misc.id)
    WHERE misc.lifecyclestate <> 'deleted'
    AND co.objectnumber NOT IN
    (   SELECT DISTINCT co.objectnumber
        FROM collectionobjects_common co
        JOIN hierarchy h1 ON (co.id = h1.id)
        JOIN relations_common rc ON (h1.name = rc.objectcsid AND rc.subjectdocumenttype='CollectionObject' AND rc.relationshiptype='hasBroader'))
    %s
    GROUP BY %s
    ORDER BY %s
    """ % (str(selectedfield), str(additionaljoin2), str(additionalwhere), str(fieldalias), str(fieldalias))
    
    objects.execute(getmuseumnumbercounts)
    result1 = objects.fetchall()
    
    objects.execute(getobjectpiecetotalcounts)
    result2 = objects.fetchall()
    
    objects.execute(getobjectpiecetruecounts)
    result3 = objects.fetchall()

    if len(result2) - len(result1) == 1:
        listify = list(result1)
        listify.append(["not cataloged",0,None,None,None,None])
        listify.sort()
        result1 = tuple(listify)
        listify2 = list(result2)
        listify2.sort()
        result2 = tuple(listify2)
        listify3 = list(result3)
        listify3.sort()
        result3 = tuple(listify3)
        
    # Replace all Nones with 0 and reduce to single row of values per grouping variable
    replresult1 = replNone(result1)
    replresult2 = replNone(result2)
    replresult3 = replNone(result3)
    result = tuple(map(lambda x, y, z: map(sum, zip(x, y, z)), replresult1, replresult2, replresult3))

    # Prepend the grouping variable
    i = 0
    results = ()
    for res in result:
        r = list(res)
        res.insert(0, result1[i][0])
        results += (tuple(res),)
        i += 1
    return results

# ######################### Get counts by continent and object type #############################

def continentcounts(continents, objecttypes, totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config):
    timepoint0 = time.time()
    
    pahmadb  = psycopg2.connect(config.get('connect','connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    for continent in continents:
        for objecttype in objecttypes:
            getmuseumnumbercounts = """
SELECT '""" + continent[2] + objecttype[1] + """' AS Continent, COUNT(*) AS totalMusNoCount, NULL::INTEGER AS totalObjectCount, NULL::INTEGER AS trueObjectCount, NULL::INTEGER AS totalPieceCount, NULL::INTEGER AS truePieceCount
FROM collectionobjects_common co
JOIN collectionobjects_pahma cp ON (co.id=cp.id)
JOIN utils.object_place_location opl ON (opl.id = co.id)
JOIN misc ON (co.id=misc.id)
WHERE misc.lifecyclestate <> 'deleted' AND cp.iscomponent = 'no' AND opl.csid_hierarchy LIKE '""" + continent[1] + """' AND co.collection """ + objecttype[0]

            getobjectpiecetotalcounts = """
SELECT '""" + continent[2] + objecttype[1] + """' AS Continent, NULL::INTEGER AS totalMusNoCount, COUNT(*) AS totalObjectCount, NULL::INTEGER AS trueObjectCount, SUM(co.numberofobjects) AS totalPieceCount, NULL::INTEGER AS truePieceCount
FROM collectionobjects_common co
JOIN utils.object_place_location opl ON (opl.id = co.id)
JOIN misc ON (co.id=misc.id)
WHERE misc.lifecyclestate <> 'deleted' AND opl.csid_hierarchy LIKE '""" + continent[1] + """' AND co.collection """ + objecttype[0]

            getobjectpiecetruecounts = """    
SELECT '""" + continent[2] + objecttype[1] + """' AS Continent, NULL::INTEGER AS totalMusNoCount, NULL::INTEGER AS totalObjectCount, COUNT(*) AS trueObjectCount, NULL::INTEGER AS totalPieceCount, SUM(co.numberofobjects) AS truePieceCount
FROM collectionobjects_common co
JOIN utils.object_place_location opl ON (opl.id = co.id)
JOIN misc ON (co.id=misc.id)
WHERE misc.lifecyclestate <> 'deleted' AND opl.csid_hierarchy LIKE '""" + continent[1] + """' AND co.collection """ + objecttype[0] + """
AND co.objectnumber NOT IN
(   SELECT DISTINCT co.objectnumber
    FROM collectionobjects_common co
    JOIN hierarchy h1 ON (co.id = h1.id)
    JOIN relations_common rc ON (h1.name = rc.objectcsid AND rc.subjectdocumenttype='CollectionObject' AND rc.relationshiptype='hasBroader'))"""
    
            objects.execute(getmuseumnumbercounts)
            result1 = objects.fetchall()
    
            objects.execute(getobjectpiecetotalcounts)
            result2 = objects.fetchall()
    
            objects.execute(getobjectpiecetruecounts)
            result3 = objects.fetchall()
        
            # Replace all Nones with 0 and reduce to single row of values per grouping variable
            replresult1 = replNone(result1)
            replresult2 = replNone(result2)
            replresult3 = replNone(result3)
            combinedresult = tuple(map(lambda x, y, z: map(sum, zip(x, y, z)), replresult1, replresult2, replresult3))

            # Prepend the grouping variable
            results = ()
            for result in combinedresult:
                r = list(result)
                result.insert(0, result1[0][0])
                results += (tuple(result))

            gatherPahmaStats.processrowofstats(results, 'objByCntntType', 'By continent and object type', totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config)

    notinanycontinent = """
AND (opl.csid_hierarchy NOT LIKE '%83e9ac8e-0cc1-4f22-9697-e8340abdd4e6%' 
AND opl.csid_hierarchy NOT LIKE '%58741091-d73e-4e0b-939a-c7e4ca54ee34%'
AND opl.csid_hierarchy NOT LIKE '%5c94ab58-85a5-4966-8bd5-ca147375b830%'
AND opl.csid_hierarchy NOT LIKE '%76fa189a-77dc-41c8-8e9a-e8b38a5d2bf6%'
AND opl.csid_hierarchy NOT LIKE '%a9b47e39-22f2-49e7-8598-ca184c671f45%'
AND opl.csid_hierarchy NOT LIKE '%c8cd4259-5d19-4786-8758-b16aa2120024%')"""
    
    for objecttype in objecttypes:
        getmuseumnumbercounts = """
SELECT 'Continent unknown""" + objecttype[1] + """' AS Continent, COUNT(*) AS totalMusNoCount, NULL::INTEGER AS totalObjectCount, NULL::INTEGER AS trueObjectCount, NULL::INTEGER AS totalPieceCount, NULL::INTEGER AS truePieceCount
FROM collectionobjects_common co
JOIN collectionobjects_pahma cp ON (co.id=cp.id)
JOIN utils.object_place_location opl ON (opl.id = co.id)
JOIN misc ON (co.id=misc.id)
WHERE misc.lifecyclestate <> 'deleted' AND cp.iscomponent = 'no' """ + notinanycontinent + """ AND co.collection """ + objecttype[0]

        getobjectpiecetotalcounts = """
SELECT 'Continent unknown""" + objecttype[1] + """' AS Continent, NULL::INTEGER AS totalMusNoCount, COUNT(*) AS totalObjectCount, NULL::INTEGER AS trueObjectCount, SUM(co.numberofobjects) AS totalPieceCount, NULL::INTEGER AS truePieceCount
FROM collectionobjects_common co
JOIN utils.object_place_location opl ON (opl.id = co.id)
JOIN misc ON (co.id=misc.id)
WHERE misc.lifecyclestate <> 'deleted' """ + notinanycontinent + """ AND co.collection """ + objecttype[0]

        getobjectpiecetruecounts = """    
SELECT 'Continent unknown""" + objecttype[1] + """' AS Continent, NULL::INTEGER AS totalMusNoCount, NULL::INTEGER AS totalObjectCount, COUNT(*) AS trueObjectCount, NULL::INTEGER AS totalPieceCount, SUM(co.numberofobjects) AS truePieceCount
FROM collectionobjects_common co
JOIN utils.object_place_location opl ON (opl.id = co.id)
JOIN misc ON (co.id=misc.id)
WHERE misc.lifecyclestate <> 'deleted' """ + notinanycontinent + """ AND co.collection """ + objecttype[0] + """
AND co.objectnumber NOT IN
(   SELECT DISTINCT co.objectnumber
    FROM collectionobjects_common co
    JOIN hierarchy h1 ON (co.id = h1.id)
    JOIN relations_common rc ON (h1.name = rc.objectcsid AND rc.subjectdocumenttype='CollectionObject' AND rc.relationshiptype='hasBroader'))"""

        objects.execute(getmuseumnumbercounts)
        result1 = objects.fetchall()
    
        objects.execute(getobjectpiecetotalcounts)
        result2 = objects.fetchall()
    
        objects.execute(getobjectpiecetruecounts)
        result3 = objects.fetchall()
        
        # Replace all Nones with 0 and reduce to single row of values per grouping variable
        replresult1 = replNone(result1)
        replresult2 = replNone(result2)
        replresult3 = replNone(result3)
        combinedresult = tuple(map(lambda x, y, z: map(sum, zip(x, y, z)), replresult1, replresult2, replresult3))

        # Prepend the grouping variable
        results = ()
        for result in combinedresult:
            r = list(result)
            result.insert(0, result1[0][0])
            results += (tuple(result))

        gatherPahmaStats.processrowofstats(results, 'objByCntntType', 'By continent and object type', totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config)

############################### Replace values of "None" with 0 #####################################

def replNone(repl):
    tup = ()
    for t in repl:
        tmp = list(t[1:])
        for i in range(len(tmp)):
            tmp[i] = tmp[i] or 0
        t = tuple(tmp)
        tup += (t,)
    return tup

###################### Write the statistics to the utils.collectionstats table #####################

def doarchivestats(dbsource, statgroup, stattarget, statmetric, label, unixruntime, isoruntime, statvalue, statpercent, config):

    pahmadb  = psycopg2.connect(config.get('connect','connect_string2'))
    cursor  = pahmadb.cursor()
    cursor.execute(timeoutcommand)

    archivestats = """
    INSERT INTO utils.collectionstats (dbsource, statgroup, stattarget, statmetric, label, unixruntime, isoruntime, statvalue, statpercent)
    VALUES ('%s', '%s', '%s', '%s', '%s', %s, '%s', %s, %s)""" % (dbsource, statgroup, stattarget, statmetric, label, str(unixruntime), str(isoruntime), str(statvalue), str(statpercent))
    
    cursor.execute(archivestats)
    pahmadb.commit()
    pahmadb.close()

 ###################################################################################################
