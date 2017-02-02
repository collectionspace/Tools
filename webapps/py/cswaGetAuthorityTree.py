#!/usr/bin/python

import sys
import psycopg2

conn = None

timeoutcommand = "set statement_timeout to 600000; SET NAMES 'utf8';"


def openConnection(connect_string):
    global conn

    try:
        conn = psycopg2.connect(connect_string)
    except Exception:
        raise
        print "In openConnection(), unable to open connection"
        sys.exit(1)


def closeConnection():
    if conn:
        conn.close()


def dropIfExistsAuthorityHierarchyTable():
    query = "DROP TABLE IF exists authorityname_temp CASCADE"

    cursor = conn.cursor()
    cursor.execute(query)
    cursor.close()
    conn.commit()


def createAuthorityHierarchyTable(authority, primarytype, term):
    query = """
    WITH authorityname_hierarchyquery as (
    SELECT
      h.name termcsid, 
      regexp_replace(pc.refname, '^.*\\)''(.*)''$', '\\1') term,  
      rc.objectcsid broaderauthoritycsid,  
      regexp_replace(pc2.refname, '^.*\\)''(.*)''$', '\\1') broaderterm,
      1 AS level  
    FROM public.%s_common pc 
      JOIN hierarchy h ON (pc.id = h.id AND h.primarytype='%s') 
      JOIN public.relations_common rc ON (h.name = rc.subjectcsid) 
      JOIN hierarchy h2 ON (h2.primarytype = '%s'
                            AND rc.objectcsid = h2.name) 
      JOIN %s_common pc2 ON (pc2.id = h2.id)
    )
    SELECT *
    INTO TEMPORARY authorityname_temp
    FROM authorityname_hierarchyquery
    WHERE %s ='%s'
  """

    #print query
    index1 = "CREATE INDEX broaderterm_ndx_temp ON authorityname_temp( broaderterm )"
    index2 = "CREATE INDEX termcsid_ndx_temp ON authorityname_temp( termcsid )"

    cursor = conn.cursor()
    term = term.replace("'", "''") # escape single quotes for psql
    cursor.execute(query % (authority, primarytype, primarytype, authority, 'broaderterm', term))
    res = cursor.rowcount
    if res == 0:
        dropIfExistsAuthorityHierarchyTable()
        cursor.execute(query % (authority, primarytype, primarytype, authority, 'term', term))
        res = cursor.rowcount
        #cursor.execute( index1 )
        #cursor.execute(index2)

    cursor.close()
    #print "Inserted %d rows" % res

    conn.commit()


def updateAuthorityHierarchyTable(authority, primarytype, n):
    query = """
    INSERT INTO authorityname_temp
    SELECT
      h.name termcsid, 
      regexp_replace(pc.refname, '^.*\\)''(.*)''$', '\\1') AS term,  
      rc.objectcsid broaderauthoritycsid,  
      regexp_replace(pc2.refname, '^.*\\)''(.*)''$', '\\1') AS broaderterm,
      %s AS level  
    FROM %s_common pc 
      JOIN hierarchy h ON (pc.id = h.id AND h.primarytype='%s') 
      JOIN relations_common rc ON (h.name = rc.subjectcsid) 
      JOIN hierarchy h2 ON (h2.primarytype = '%s'
                            AND rc.objectcsid = h2.name)
      JOIN %s_common pc2 ON (pc2.id = h2.id)
    WHERE rc.objectcsid IN (SELECT termcsid from authorityname_temp WHERE level = %s)
  """ % (n + 1, authority, primarytype, primarytype, authority, n)

    #print '****',n
    #print query
    cursor = conn.cursor()
    cursor.execute(timeoutcommand)
    cursor.execute(query)
    res = cursor.rowcount
    cursor.close()
    #print "Updated %d rows for level %s" % (res,n+1)

    conn.commit()

    return res


def getAuthority(authority, primarytype, term, connect_string):
    openConnection(connect_string)
    #print 'getting children for ',term
    dropIfExistsAuthorityHierarchyTable()

    createAuthorityHierarchyTable(authority, primarytype, term)

    for i in range(1, 20):
        res = updateAuthorityHierarchyTable(authority, primarytype, i)
        if res == 0:
            #print "performed %d loops" % (i+1)
            break

    query = """SELECT term,level FROM authorityname_temp"""

    cursor = conn.cursor()
    cursor.execute(query)
    res = cursor.fetchall()
    notFound = True
    for r in res:
        if r[0] == term:
            notFound = False
            break
    if notFound:
        res.append([term, 0])

    cursor.close()

    dropIfExistsAuthorityHierarchyTable()

    conn.commit()

    closeConnection()
    return res


def getChildren(authority, primarytype, term, connect_string):
    openConnection(connect_string)

    query = """
    WITH authorityname_hierarchyquery as (
    SELECT
      h.name AS authoritycsid, 
      regexp_replace(pc.refname, '^.*\\)''(.*)''$', '\\1') AS term,  
      rc.objectcsid AS broaderauthoritycsid,  
      regexp_replace(pc2.refname, '^.*\\)''(.*)''$', '\\1') AS broaderterm,
      0 AS level  
    FROM public.%s_common pc 
      JOIN hierarchy h ON (pc.id = h.id AND h.primarytype='%s') 
      JOIN public.relations_common rc ON (h.name = rc.subjectcsid) 
      JOIN hierarchy h2 ON (h2.primarytype = '%s'
                            AND rc.objectcsid = h2.name) 
      JOIN %s_common pc2 ON (pc2.id = h2.id)
    )
    SELECT *
    FROM authorityname_hierarchyquery
    WHERE %s ='%s'
  """
    cursor = conn.cursor()
    term = term.replace("'", "''") # escape single quotes for psql
    cursor.execute(query % (authority, primarytype, primarytype, authority, 'broaderterm', term))
    res = cursor.fetchall()
    cursor.close()

    closeConnection()
    return res


if __name__ == "__main__":

    print 'starting to get some locations from botgarden-dev'
    # get some taxonomic names and locations from botgarden-dev
    connect_string    = "host=dba-postgres-dev-32.ist.berkeley.edu port=5113 dbname=botgarden_domain_botgarden user=reporter_botgarden password=xxxinsertpasswordherexxx sslmode=require"
    # get some locations from botgarden-dev
    primarytype = 'Locationitem'
    authority = 'locations'
    for p in ('1002, Green House 2', 'Californian', 'Damask, Roses', 'Crops of the World'):
        locations = getAuthority(authority, primarytype, p, connect_string)
        print p, ':', len(locations)
        if len(locations) < 100:
            print locations

    #sys.exit(1)

    print 'starting to get some places from pahma-dev'
    # get some places and materials from PAHMA-dev
    connect_string    = "host=dba-postgres-dev-32.ist.berkeley.edu port=5107 dbname=pahma_domain_pahma user=reporter_pahma password=xxxinsertpasswordherexxx sslmode=require"
    primarytype = 'Placeitem'
    authority = 'places'

    for p in ('Gebel Garn, Egypt, Northern Africa', 'Giza, Cemetery 1000, Giza, Giza plateau', 'Europe',
              'North America, The Americas', 'South America, The Americas', 'China, Central Asia, Asia',
              'Central Africa, Africa', 'Africa', 'Asia'):
        places = getAuthority(authority, primarytype, p, connect_string)
        print p, ':', len(places)
        if len(places) < 100:
            print places

    print 'starting to get some taxa from botgarden-dev'
    # test getAuthority
    primarytype = 'TaxonTenant35'
    authority = 'taxon'
    for p in ('Hebe parviflora', 'Dracophilus delaetianum', 'ROSACEAE', 'Ginkgo', 'ASTERACEAE'):
        taxa = getAuthority(authority, primarytype, p, connect_string)
        print p, ':', len(taxa)
        if len(taxa) < 100:
            print taxa

    print 'starting to get some places from botgarden-dev'
    primarytype = 'Placeitem'
    authority = 'places'
    for p in ('Europe', 'North America, The Americas', 'South America, The Americas', 'China, Central Asia, Asia',
              'Central Africa, Africa', 'Africa', 'Asia'):
        places = getAuthority(authority, primarytype, p, connect_string)
        print p, ':', len(places)
        if len(places) < 100:
            print places

    print 'starting to get children of some taxa from botgarden-dev'
    # test getChildren
    primarytype = 'TaxonTenant35'
    authority = 'taxon'
    for p in ('Hebe parviflora', 'Dracophilus delaetianum', 'ROSACEAE', 'Ginkgo', 'ASTERACEAE'):
        taxa = getChildren(authority, primarytype, p, connect_string)
        print p, ':', len(taxa)
        if len(taxa) < 100:
            print taxa
