--
--
--

CREATE OR REPLACE FUNCTION utils.populateTaxonHierarchyTable() RETURNS void AS
$$
  TRUNCATE TABLE utils.taxon_hierarchy;

  WITH taxon_hierarchyquery as (
   SELECT
      h.name taxoncsid,
      regexp_replace(tc.refname, '^.*\)''(.*)''$', '\1') taxon,
      rc.objectcsid broadertaxoncsid,
      regexp_replace(tc2.refname, '^.*\)''(.*)''$', '\1') broadertaxon
    FROM public.taxon_common tc
      INNER JOIN misc m ON (tc.id=m.id AND m.lifecyclestate<>'deleted')
      LEFT OUTER JOIN hierarchy h ON (tc.id = h.id AND h.primarytype='Taxon')
      LEFT OUTER JOIN public.relations_common rc ON (h.name = rc.subjectcsid)
      LEFT OUTER JOIN hierarchy h2 ON (h2.primarytype = 'Taxon'
                            AND rc.objectcsid = h2.name)
      LEFT OUTER JOIN taxon_common tc2 ON (tc2.id = h2.id)
    )
  INSERT INTO utils.taxon_hierarchy
  SELECT DISTINCT
    taxoncsid, taxon,
    broadertaxoncsid as parentid,
    broadertaxoncsid as nextcsid,
    taxon AS taxon_hierarchy,
    taxoncsid AS csid_hierarchy
  FROM  taxon_hierarchyquery;
$$
LANGUAGE sql

