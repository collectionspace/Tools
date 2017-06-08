#!/usr/bin/env /usr/bin/python

import time
import sys
import cgi
import psycopg2
import locale

locale.setlocale(locale.LC_ALL, 'en_US')

timeoutcommand = 'set statement_timeout to 300000'

# ###############################

def getnamesoversixtycharslong(config):

    pahmadb  = psycopg2.connect(config.get('connect', 'connect_string'))
    objects  = pahmadb.cursor()
    objects.execute(timeoutcommand)

    getnamesoversixtycharslong = """
   SELECT co.objectnumber, ong.objectname, bd.item, csid.name
FROM collectionobjects_common co
JOIN hierarchy csid ON (co.id = csid.id)
JOIN collectionobjects_pahma cp ON (co.id = cp.id)
FULL OUTER JOIN collectionobjects_common_briefdescriptions bd ON (bd.id = co.id AND bd.pos = 0)
JOIN misc ON (co.id = misc.id)
JOIN hierarchy h ON (co.id = h.parentid AND h.name = 'collectionobjects_common:objectNameList')
JOIN objectnamegroup ong ON (ong.id = h.id AND LENGTH(ong.objectname) > 60)
WHERE misc.lifecyclestate <> 'deleted'
ORDER BY cp.sortableobjectnumber"""

    objects.execute(getnamesoversixtycharslong)
    results=objects.fetchall()
    return results

# ###############################
