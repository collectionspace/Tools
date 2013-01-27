#!/usr/bin/python

import sys
import pgdb

#connect_string = 'localhost:nuxeo:nuxeo'
connect_string = 'pahma.cspace.berkeley.edu:nuxeo:reporter:xxxxxx'
conn = None

def openConnection():
  global conn

  try:
    conn = pgdb.connect( connect_string )
  except Exception:
    print "In openConnection(), unable to open connection"
    sys.exit( 1 )

def closeConnection():
  if conn:
    conn.close()

def dropIfExistsPlacenameHierarchyTable():
  query = "DROP TABLE IF exists placename_temp CASCADE"

  cursor = conn.cursor()
  cursor.execute( query )
  cursor.close()
  conn.commit()

def createPlacenameHierarchyTable(place):
  query = """
    WITH placename_hierarchyquery as (
    SELECT
      h.name placecsid, 
      regexp_replace(pc.refname, '^.*\\)''(.*)''$', '\\1') placename,  
      rc.objectcsid broaderplacecsid,  
      regexp_replace(pc2.refname, '^.*\\)''(.*)''$', '\\1') broaderplacename,
      0 AS level  
    FROM public.places_common pc 
      JOIN hierarchy h ON (pc.id = h.id AND h.primarytype='Placeitem') 
      JOIN public.relations_common rc ON (h.name = rc.subjectcsid) 
      JOIN hierarchy h2 ON (h2.primarytype = 'Placeitem'
                            AND rc.objectcsid = h2.name) 
      JOIN places_common pc2 ON (pc2.id = h2.id)
    )
    SELECT *
    INTO placename_temp
    FROM placename_hierarchyquery
    WHERE %s ='%s'
  """

  #print query
  index1 = "CREATE INDEX nexcsid_ndx_temp ON placename_temp( broaderplacename )" 
  index2 = "CREATE INDEX placecsid_ndx_temp ON placename_temp( placecsid )" 

  cursor = conn.cursor()
  cursor.execute( query % ('broaderplacename',place) )
  res = cursor.rowcount
  if res == 0:
    dropIfExistsPlacenameHierarchyTable()
    cursor.execute( query % ('placename',place) )
    res = cursor.rowcount
  cursor.execute( index1 )
  cursor.execute( index2 )

  cursor.close()
  #print "Inserted %d rows" % res

  conn.commit()

def updatePlacenameHierarchyTable(n):
  query = """
    INSERT INTO placename_temp
    SELECT
      h.name placecsid, 
      regexp_replace(pc.refname, '^.*\\)''(.*)''$', '\\1') AS placename,  
      rc.objectcsid broaderplacecsid,  
      regexp_replace(pc2.refname, '^.*\\)''(.*)''$', '\\1') AS broaderplacename,
      """ + str(n+1) + """ AS level  
    FROM places_common pc 
      JOIN hierarchy h ON (pc.id = h.id AND h.primarytype='Placeitem') 
      JOIN relations_common rc ON (h.name = rc.subjectcsid) 
      JOIN hierarchy h2 ON (h2.primarytype = 'Placeitem'
                            AND rc.objectcsid = h2.name)
      JOIN places_common pc2 ON (pc2.id = h2.id)
    WHERE rc.objectcsid IN (SELECT placecsid from placename_temp WHERE level = """ + str(n) + """)
  """ 

  cursor = conn.cursor()
  cursor.execute( query )
  res = cursor.rowcount
  cursor.close()
  #print "Updated %d rows" % res

  conn.commit()

  return res

def getPlaces(place):


  openConnection()
  #print 'getting children for ',place
  dropIfExistsPlacenameHierarchyTable()

  createPlacenameHierarchyTable(place)

  for i in range(20):
    res = updatePlacenameHierarchyTable(i)
    if res == 0:
       #print "performed %d loops" % (i+1)
       break

  query = """
    SELECT placename FROM placename_temp
"""

  cursor = conn.cursor()
  cursor.execute( query )
  res = cursor.fetchall()
  res = [r[0] for r in res]
  cursor.close()

  conn.commit()

  closeConnection()
  return res

if __name__ == "__main__":

  for p in ('Gebel Garn, Egypt, Northern Africa','Giza, Cemetery 1000, Giza, Giza plateau','Europe','North America, The Americas','South America, The Americas','China, Central Asia, Asia','Central Africa, Africa','Africa','Asia'):
      places = getPlaces(p)  
      print p,':',len(places)  
      if len(places) < 100:
	print places

