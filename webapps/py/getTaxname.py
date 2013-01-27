#!/usr/bin/python

import sys
import pgdb

#connect_string = 'localhost:nuxeo:nuxeo'
connect_string = 'botgarden-dev.cspace.berkeley.edu:nuxeo:reporter:xxxxxx'
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

def dropIfExistsTaxnameHierarchyTable():
  query = "DROP TABLE IF exists taxonname_temp CASCADE"

  cursor = conn.cursor()
  cursor.execute( query )
  cursor.close()
  conn.commit()

def createTaxnameHierarchyTable(taxon):
  query = """
    WITH taxonname_hierarchyquery as (
    SELECT
      h.name taxoncsid, 
      regexp_replace(pc.refname, '^.*\\)''(.*)''$', '\\1') taxonname,  
      rc.objectcsid broadertaxoncsid,  
      regexp_replace(pc2.refname, '^.*\\)''(.*)''$', '\\1') broadertaxonname,
      0 AS level  
    FROM public.taxon_common pc 
      JOIN hierarchy h ON (pc.id = h.id AND h.primarytype='TaxonTenant35') 
      JOIN public.relations_common rc ON (h.name = rc.subjectcsid) 
      JOIN hierarchy h2 ON (h2.primarytype = 'TaxonTenant35'
                            AND rc.objectcsid = h2.name) 
      JOIN taxon_common pc2 ON (pc2.id = h2.id)
    )
    SELECT *
    INTO taxonname_temp
    FROM taxonname_hierarchyquery
    WHERE %s ='%s'
  """

  #print query
  index1 = "CREATE INDEX taxonbrdcsid_ndx_temp ON taxonname_temp( broadertaxonname )" 
  index2 = "CREATE INDEX taxoncsid_ndx_temp ON taxonname_temp( taxoncsid )" 

  cursor = conn.cursor()
  cursor.execute( query % ('broadertaxonname',taxon) )
  res = cursor.rowcount
  if res == 0:
    dropIfExistsTaxnameHierarchyTable()
    cursor.execute( query % ('taxonname',taxon) )
    res = cursor.rowcount
  cursor.execute( index1 )
  cursor.execute( index2 )

  cursor.close()
  #print "Inserted %d rows" % res

  conn.commit()

def updateTaxnameHierarchyTable(n):
  query = """
    INSERT INTO taxonname_temp
    SELECT
      h.name taxoncsid, 
      regexp_replace(pc.refname, '^.*\\)''(.*)''$', '\\1') AS taxonname,  
      rc.objectcsid broadertaxoncsid,  
      regexp_replace(pc2.refname, '^.*\\)''(.*)''$', '\\1') AS broadertaxonname,
      """ + str(n+1) + """ AS level  
    FROM taxon_common pc 
      JOIN hierarchy h ON (pc.id = h.id AND h.primarytype='TaxonTenant35') 
      JOIN relations_common rc ON (h.name = rc.subjectcsid) 
      JOIN hierarchy h2 ON (h2.primarytype = 'TaxonTenant35'
                            AND rc.objectcsid = h2.name)
      JOIN taxon_common pc2 ON (pc2.id = h2.id)
    WHERE rc.objectcsid IN (SELECT taxoncsid from taxonname_temp WHERE level = """ + str(n) + """)
  """ 

  cursor = conn.cursor()
  cursor.execute( query )
  res = cursor.rowcount
  cursor.close()
  #print "Updated %d rows" % res

  conn.commit()

  return res

def getTaxon(taxon):


  openConnection()
  #print 'getting children for ',taxon
  dropIfExistsTaxnameHierarchyTable()

  createTaxnameHierarchyTable(taxon)

  for i in range(20):
    res = updateTaxnameHierarchyTable(i)
    if res == 0:
       #print "performed %d loops" % (i+1)
       break

  query = """
    SELECT taxonname,level FROM taxonname_temp
"""

  cursor = conn.cursor()
  cursor.execute( query )
  res = cursor.fetchall()
  #res = [r[0] for r in res]
  cursor.close()

  conn.commit()

  closeConnection()
  return res


def getChildren(taxon):

  openConnection()
  
  query = """
    SELECT
      h.name taxoncsid, 
      regexp_replace(pc.refname, '^.*\\)''(.*)''$', '\\1') taxonname,  
      rc.objectcsid broadertaxoncsid,  
      regexp_replace(pc2.refname, '^.*\\)''(.*)''$', '\\1') broadertaxonname,
      0 AS level  
    FROM public.taxon_common pc 
      JOIN hierarchy h ON (pc.id = h.id AND h.primarytype='TaxonTenant35') 
      JOIN public.relations_common rc ON (h.name = rc.subjectcsid) 
      JOIN hierarchy h2 ON (h2.primarytype = 'TaxonTenant35'
                            AND rc.objectcsid = h2.name) 
      JOIN taxon_common pc2 ON (pc2.id = h2.id)
    WHERE %s ='%s'
  """
  cursor = conn.cursor()
  cursor.execute( query % ('broadertaxonname',taxon) )
  res = cursor.fetchall()
  cursor.close()

  closeConnection()
  return res


if __name__ == "__main__":

  # test getChildren
  for p in ('Hebe parviflora','Dracophilus delaetianum','ROSACEAE','Ginkgo','ASTERACEAE'):
      taxa = getChildren(p)  
      print p,':',len(taxa)  
      if len(taxa) < 100:
	print taxa

  # test getTaxon
  for p in ('Hebe parviflora','Dracophilus delaetianum','ROSACEAE','Ginkgo','ASTERACEAE'):
      taxa = getTaxon(p)  
      print p,':',len(taxa)  
      if len(taxa) < 100:
	print taxa

