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
import gatherPahmaStatsDB
   
# #################################### Collection Stats web app #######################################

def doCollectionStats(config):
    unixruntime = time.time()
    isoruntime = datetime.datetime.fromtimestamp(int(unixruntime)).strftime('%Y-%m-%d %H:%M:%S')

    dbsource = config.get('connect','dbsource')

# ############################ Getting grand total counts of whole collection ############################
    totalobjcounts = gatherPahmaStatsDB.gettotalobjcount(config)
    totalMusNoCountOverall = totalobjcounts[0][0]
    totalObjectCountOverall = totalobjcounts[1][0]
    objectOverCountOverall = totalobjcounts[2][0]
   
    try:
        percentObjectOverCountOverall = 100 * float(objectOverCountOverall)/float(totalObjectCountOverall)
    except ZeroDivisionError:
        percentObjectOverCountOverall = 0
    trueObjectCountOverall = int(totalObjectCountOverall) - int(objectOverCountOverall)
    totalPieceCountOverall = totalobjcounts[3][0]
    pieceOverCountOverall = totalobjcounts[4][0]
    try:
        percentPieceOverCountOverall = 100 * float(pieceOverCountOverall)/float(totalPieceCountOverall)
    except ZeroDivisionError:
        percentPieceOverCountOverall = 0
    truePieceCountOverall = int(totalPieceCountOverall) - int(pieceOverCountOverall)
   
    #sys.exit()

    gatherPahmaStatsDB.doarchivestats(dbsource, 'totalCounts', 'musNumbers', 'totalMusNoCount', 'wholeCollection', unixruntime, isoruntime, totalMusNoCountOverall, 100, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, 'totalCounts', 'objects', 'totalObjectCount', 'wholeCollection', unixruntime, isoruntime, totalObjectCountOverall, 100, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, 'totalCounts', 'objects', 'objectOverCount', 'wholeCollection', unixruntime, isoruntime, objectOverCountOverall, percentObjectOverCountOverall, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, 'totalCounts', 'objects', 'trueObjectCount', 'wholeCollection', unixruntime, isoruntime, trueObjectCountOverall, 100, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, 'totalCounts', 'pieces', 'totalPieceCount', 'wholeCollection', unixruntime, isoruntime, totalPieceCountOverall, 100, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, 'totalCounts', 'pieces', 'pieceOvercount', 'wholeCollection', unixruntime, isoruntime, pieceOverCountOverall, percentPieceOverCountOverall, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, 'totalCounts', 'pieces', 'truePieceCount', 'wholeCollection', unixruntime, isoruntime, truePieceCountOverall, 100, config)
   
# ############################ Getting counts by object types ############################

    additionaljoin1 = ''
    additionaljoin2 = ''
    additionalwhere = ''
    fieldalias = 'objecttype'
    field = 'co.collection'
    countresults = gatherPahmaStatsDB.getgroupedobjcounts(additionaljoin1, additionaljoin2, additionalwhere, fieldalias, field, config)
    processstats(countresults, 'objByObjType', 'By object type', totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config)

# ############################ Getting counts by legacy catalogs ############################

    additionaljoin1 = '' ##### Already included in the generic query #####
    additionaljoin2 = 'JOIN collectionobjects_pahma cp ON (co.id=cp.id)'
    additionalwhere = ''
    fieldalias = 'tmslegacydepartment'
    field = 'cp.pahmatmslegacydepartment'
    countresults = gatherPahmaStatsDB.getgroupedobjcounts(additionaljoin1, additionaljoin2, additionalwhere, fieldalias, field, config)
    processstats(countresults, 'objByLegCat', 'By legacy catalog', totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config)

# ############################ Getting counts by collections managers ############################
   
    additionaljoin1 = 'JOIN collectionobjects_common_responsibledepartments cm ON (co.id=cm.id)'
    additionaljoin2 = 'JOIN collectionobjects_common_responsibledepartments cm ON (co.id=cm.id)'
    additionalwhere = ''
    fieldalias = 'collectionManager'
    field = 'cm.item'
    countresults = gatherPahmaStatsDB.getgroupedobjcounts(additionaljoin1, additionaljoin2, additionalwhere, fieldalias, field, config)
    processstats(countresults, 'objByCollMan', 'By collection manager', totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config)

# ############################ Getting counts by accession status ############################

    additionaljoin1 = 'JOIN collectionobjects_pahma_pahmaobjectstatuslist osl ON (co.id = osl.id)'
    additionaljoin2 = 'JOIN collectionobjects_pahma_pahmaobjectstatuslist osl ON (co.id = osl.id)'
    additionalwhere = ''
    fieldalias = 'accessionStatus'
    field = 'osl.item'
    countresults = gatherPahmaStatsDB.getgroupedobjcounts(additionaljoin1, additionaljoin2, additionalwhere, fieldalias, field, config)
    processstats(countresults, 'objByAccStatus', 'By accession status', totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config)

# ############################ Getting counts by ethnographic file code ############################

    additionaljoin1 = 'JOIN collectionobjects_pahma_pahmaethnographicfilecodelist efc ON (co.id = efc.id AND efc.pos = 0)'
    additionaljoin2 = 'JOIN collectionobjects_pahma_pahmaethnographicfilecodelist efc ON (co.id = efc.id AND efc.pos = 0)'
    additionalwhere = ''
    fieldalias = 'ethnofilecode'
    field = """regexp_replace(efc.item, '^.*\\)''(.*)''$', '\\1')"""
    countresults = gatherPahmaStatsDB.getgroupedobjcounts(additionaljoin1, additionaljoin2, additionalwhere, fieldalias, field, config)
    processstats(countresults, 'objByFileCode', 'By ethnographic file code', totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config)

# ############################ Getting counts by continent and object type ############################

    continents = [
        ('Africa', '%83e9ac8e-0cc1-4f22-9697-e8340abdd4e6%', 'African'), 
        ('Europe', '%58741091-d73e-4e0b-939a-c7e4ca54ee34%', 'European'), 
        ('Oceania', '%5c94ab58-85a5-4966-8bd5-ca147375b830%', 'Oceanian'), 
        ('Asia', '%76fa189a-77dc-41c8-8e9a-e8b38a5d2bf6%', 'Asian'), 
        ('North America', '%a9b47e39-22f2-49e7-8598-ca184c671f45%', 'North American'), 
        ('South America', '%c8cd4259-5d19-4786-8758-b16aa2120024%', 'South American')]
    objecttypes = [
        ("""= 'archaeology'""", " archaeology"), 
        ("""= '(not specified)'""", " (not specified)"),
        ("""= 'ethnography'""", " ethnography"),
        ("""IS NULL""", " (none)"),
        ("""= 'unknown'""", " (unknown)"),
        ("""= 'sample'""", " samples"),
        ("""= 'documentation'""", " documentation"),
        ("""= 'indeterminate'""", " (indeterminate)")]

    gatherPahmaStatsDB.continentcounts(continents, objecttypes, totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config)

# ############################ Getting images counts by object type code ############################

    additionaljoin1 = 'JOIN hierarchy h1 ON (h1.id = co.id)\
    JOIN relations_common rc ON (rc.subjectcsid = h1.name)\
    JOIN hierarchy h2 ON (h2.name = rc.objectcsid)\
    JOIN media_common mc ON (mc.id = h2.id)'
    additionaljoin2 = 'JOIN hierarchy h1 ON (h1.id = co.id)\
    JOIN relations_common rc ON (rc.subjectcsid = h1.name)\
    JOIN hierarchy h2 ON (h2.name = rc.objectcsid)\
    JOIN media_common mc ON (mc.id = h2.id)'
    additionalwhere = '''AND mc.id NOT IN (\
        SELECT mcsub.id\
        FROM media_common mcsub\
        WHERE\
        (mcsub.description ILIKE 'Primary catalog card%'\
        OR mcsub.description ILIKE 'Catalog card%'\
        OR mcsub.description ILIKE 'Bulk entry catalog card%'\
        OR mcsub.description ILIKE 'Problematic catalog card%'\
        OR mcsub.description ILIKE 'Recataloged objects catalog card%'\
        OR mcsub.description ILIKE 'Revised catalog card%'\
        OR mcsub.description ILIKE 'Index%'))'''
    fieldalias = 'objecttype'
    field = 'co.collection'
    countresults = gatherPahmaStatsDB.getgroupedobjcounts(additionaljoin1, additionaljoin2, additionalwhere, fieldalias, field, config)
    processstats(countresults, 'objByImgObjType', 'Imaged objects by object type', totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config)
    
# ############################ Format multi-row statistics for writing to the utils.collectionstats database ############################

def processstats(countresults, statgroup, sectiontitle, totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config):

    icount = -1
    for countresult in countresults:
        icount += 1
        label = countresults[icount][0]
        if label:
            if "'" in label:
                label.replace("'", "''")
        totalMusNoCount = countresults[icount][1]
        totalObjectCount = countresults[icount][2]
        trueObjectCount = countresults[icount][3]
        objectOverCount = int(totalObjectCount) - int(trueObjectCount)
        try:
            percentObjectOverCount = 100 * float(objectOverCount)/float(totalObjectCount)
        except ZeroDivisionError:
            percentObjectOverCount = 0
        totalPieceCount = countresults[icount][4]
        truePieceCount = countresults[icount][5]
        pieceOverCount = int(totalPieceCount) - int(truePieceCount)
        try:
            percentPieceOverCount = 100 * float(pieceOverCount)/float(totalPieceCount)
        except ZeroDivisionError:
            percentPieceOverCount = 0

        if str(totalMusNoCount) == 'None': totalMusNoCount = 0
        if str(totalObjectCount) == 'None': totalObjectCount = 0
        if str(trueObjectCount) == 'None': trueObjectCount = 0
        if str(totalPieceCount) == 'None': totalPieceCount = 0
        if str(truePieceCount) == 'None': truePieceCount = 0

        try:
            percentOfMuseumNos = 100 * float(totalMusNoCount)/float(totalMusNoCountOverall)
        except ZeroDivisionError:
            percentOfMuseumNos = 0
        try:
            percentOfTotalObjects = 100 * float(totalObjectCount)/float(totalObjectCountOverall)
        except ZeroDivisionError:
            percentOfTotalObjects = 0
        try:
            percentOfTrueObjects = 100 * float(trueObjectCount)/float(trueObjectCountOverall)
        except ZeroDivisionError:
            percentOfTrueObjects = 0
        try:
            percentOfTotalPieces = 100 * float(totalPieceCount)/float(totalPieceCountOverall)
        except ZeroDivisionError:
            percentOfTotalPieces = 0
        try:
            percentOfTruePieces = 100 * float(truePieceCount)/float(truePieceCountOverall)
        except ZeroDivisionError:
            percentOfTruePieces = 0

        gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'musNumbers', 'totalMusNoCount', label, unixruntime, isoruntime, totalMusNoCount, percentOfMuseumNos, config)
        gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'objects', 'totalObjectCount', label, unixruntime, isoruntime, totalObjectCount, percentOfTotalObjects, config)
        gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'objects', 'objectOverCount', label, unixruntime, isoruntime, objectOverCount, percentObjectOverCount, config)
        gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'objects', 'trueObjectCount', label, unixruntime, isoruntime, trueObjectCount, percentOfTrueObjects, config)
        gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'pieces', 'totalPieceCount', label, unixruntime, isoruntime, totalPieceCount, percentOfTotalPieces, config)
        gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'pieces', 'pieceOvercount', label, unixruntime, isoruntime, pieceOverCount, percentPieceOverCount, config)
        gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'pieces', 'truePieceCount', label, unixruntime, isoruntime, truePieceCount, percentOfTruePieces, config)
    
# ############################ Format single-row statistics for writing to the utils.collectionstats database ############################

def processrowofstats(countresults, statgroup, sectiontitle, totalMusNoCountOverall, totalObjectCountOverall, trueObjectCountOverall, totalPieceCountOverall, truePieceCountOverall, unixruntime, isoruntime, dbsource, config):
    print "countresults:", countresults
    label = countresults[0]
    if label:
        if "'" in label:
            label.replace("'", "''")
    totalMusNoCount = countresults[1]
    totalObjectCount = countresults[2]
    trueObjectCount = countresults[3]
    objectOverCount = int(totalObjectCount) - int(trueObjectCount)
    try:
       percentObjectOverCount = 100 * float(objectOverCount)/float(totalObjectCount)
    except ZeroDivisionError:
         percentObjectOverCount = 0
    totalPieceCount = countresults[4]
    truePieceCount = countresults[5]
    pieceOverCount = int(totalPieceCount) - int(truePieceCount)
    try:
       percentPieceOverCount = 100 * float(pieceOverCount)/float(totalPieceCount)
    except ZeroDivisionError:
         percentPieceOverCount = 0

    try:
        percentOfMuseumNos = 100 * float(totalMusNoCount)/float(totalMusNoCountOverall)
    except ZeroDivisionError:
        percentOfMuseumNos = 0
    try:
        percentOfTotalObjects = 100 * float(totalObjectCount)/float(totalObjectCountOverall)
    except ZeroDivisionError:
        percentOfTotalObjects = 0
    try:
        percentOfTrueObjects = 100 * float(trueObjectCount)/float(trueObjectCountOverall)
    except ZeroDivisionError:
        percentOfTrueObjects = 0
    try:
        percentOfTotalPieces = 100 * float(totalPieceCount)/float(totalPieceCountOverall)
    except ZeroDivisionError:
        percentOfTotalPieces = 0
    try:
        percentOfTruePieces = 100 * float(truePieceCount)/float(truePieceCountOverall)
    except ZeroDivisionError:
        percentOfTruePieces = 0

    gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'musNumbers', 'totalMusNoCount', label, unixruntime, isoruntime, totalMusNoCount, percentOfMuseumNos, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'objects', 'totalObjectCount', label, unixruntime, isoruntime, totalObjectCount, percentOfTotalObjects, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'objects', 'objectOverCount', label, unixruntime, isoruntime, objectOverCount, percentObjectOverCount, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'objects', 'trueObjectCount', label, unixruntime, isoruntime, trueObjectCount, percentOfTrueObjects, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'pieces', 'totalPieceCount', label, unixruntime, isoruntime, totalPieceCount, percentOfTotalPieces, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'pieces', 'pieceOvercount', label, unixruntime, isoruntime, pieceOverCount, percentPieceOverCount, config)
    gatherPahmaStatsDB.doarchivestats(dbsource, statgroup, 'pieces', 'truePieceCount', label, unixruntime, isoruntime, truePieceCount, percentOfTruePieces, config)

# ###############################

if __name__ == "__main__":

    fileName = 'gatherPahmaStats.cfg'
    config = ConfigParser.RawConfigParser()
    config.read(fileName)

    doCollectionStats(config)

    sys.exit(1)
