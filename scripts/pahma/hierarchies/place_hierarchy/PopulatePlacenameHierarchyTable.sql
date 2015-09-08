-- populatePlacenameHierarchyTable
--
-- A function to insert the initial rows into the placename_hierarchy
-- table, which must already exist. The hierarchy columns will be built 
-- up later by another procedure.      

CREATE OR REPLACE FUNCTION utils.populatePlacenameHierarchyTable() RETURNS void AS
$$
  TRUNCATE TABLE utils.placename_hierarchy;

  WITH placename_hierarchyquery as (
   SELECT
      h.name placecsid,
      regexp_replace(pc.refname, '^.*\)''(.*)''$', '\1') placename,
      rc.objectcsid broaderplacecsid,
      regexp_replace(pc2.refname, '^.*\)''(.*)''$', '\1') broaderplacename
    FROM public.places_common pc
      INNER JOIN misc m ON (pc.id = m.id AND m.lifecyclestate <> 'deleted')
      LEFT OUTER JOIN hierarchy h ON (pc.id = h.id AND h.primarytype='PlaceitemTenant15')
      LEFT OUTER JOIN public.relations_common rc ON (h.name = rc.subjectcsid)
      LEFT OUTER JOIN hierarchy h2 ON (h2.primarytype = 'PlaceitemTenant15'
                            AND rc.objectcsid = h2.name)
      LEFT OUTER JOIN places_common pc2 ON (pc2.id = h2.id)
    )
  INSERT INTO utils.placename_hierarchy
  SELECT DISTINCT
    placecsid, placename,
    broaderplacecsid as parentcsid,
    broaderplacecsid as nextcsid,
    placename AS place_hierarchy,
    placecsid AS csid_hierarchy
  FROM  placename_hierarchyquery;
$$
LANGUAGE sql
