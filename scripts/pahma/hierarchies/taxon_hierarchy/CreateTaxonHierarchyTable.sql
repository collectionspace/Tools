--
--
--

CREATE OR REPLACE FUNCTION utils.createTaxonHierarchyTable() RETURNS void AS
$$
DECLARE
BEGIN
  IF NOT EXISTS ( SELECT relname
                  FROM pg_catalog.pg_class c
                       JOIN
                       pg_catalog.pg_namespace n
                       ON (n.oid = c.relnamespace)
               WHERE c.relname = 'taxon_hierarchy'
                 AND n.nspname = 'utils' )
  THEN
    CREATE TABLE utils.taxon_hierarchy (
       taxoncsid text,
       taxon text,
       parentid  text,
       nextcsid  text,
       taxon_hierarchy text,
       csid_hierarchy text );

    CREATE INDEX uth_tcsid_ndx on utils.taxon_hierarchy ( taxoncsid );
    CREATE INDEX uth_tname_ndx on utils.taxon_hierarchy ( taxon );
  END IF;
END;
$$
LANGUAGE plpgsql

