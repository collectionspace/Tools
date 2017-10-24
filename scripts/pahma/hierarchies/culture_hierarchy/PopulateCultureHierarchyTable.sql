-- populateCultureHierarchyTable
--
-- A function to insert the initial rows into the culture_hierarchy 
-- table, which must already exist. The hierarchy columns will be built 
-- up later by another procedure.      

CREATE OR REPLACE FUNCTION utils.populateCultureHierarchyTable() RETURNS void AS
$$
  TRUNCATE TABLE utils.culture_hierarchy;

  WITH culture_hierarchyquery AS (
    SELECT
      h.name culturecsid,
      regexp_replace(cnc.refname, '^.*\)''(.*)''$', '\1') culture,
      rc.objectcsid broaderculturecsid,
      regexp_replace(cnc2.refname, '^.*\)''(.*)''$', '\1') broaderculture
    FROM public.concepts_common cnc
      INNER JOIN misc m ON (cnc.id=m.id AND m.lifecyclestate<>'deleted')
      LEFT OUTER JOIN hierarchy h ON (cnc.id = h.id
                                  AND h.primarytype='Conceptitem')
      LEFT OUTER JOIN public.relations_common rc ON (h.name = rc.subjectcsid)
      LEFT OUTER JOIN hierarchy h2 ON (rc.objectcsid = h2.name
                                   AND h2.primarytype = 'Conceptitem')
      LEFT OUTER JOIN concepts_common cnc2 ON (cnc2.id = h2.id)
      WHERE cnc.refname LIKE 'urn:cspace:pahma.cspace.berkeley.edu:conceptauthorities:name(concept)%'
         OR cnc.refname LIKE 'urn:cspace:pahma.cspace.berkeley.edu:conceptauthorities:name(archculture)%'
    )
  INSERT INTO utils.culture_hierarchy
  SELECT DISTINCT
    culturecsid,
    culture,
    broaderculturecsid AS parentcsid,
    broaderculturecsid AS nextcsid,
    culture AS culture_hierarchy,
    culturecsid AS csid_hierarchy
  FROM  culture_hierarchyquery
$$
LANGUAGE sql

