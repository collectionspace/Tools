-- createCultureHierarchyTable
-- 
-- A function to create an empty culture_hierarchy table, 
-- in the utils schema, if one does not already exist.
-- It does not drop or recreate any existing table.

CREATE OR REPLACE FUNCTION utils.createCultureHierarchyTable() RETURNS void AS
$$
DECLARE
BEGIN
  IF NOT EXISTS ( SELECT relname
                  FROM pg_catalog.pg_class c
                       JOIN
                       pg_catalog.pg_namespace n
                       ON (n.oid = c.relnamespace)
               WHERE c.relname = 'culture_hierarchy'
                 AND n.nspname = 'utils' )
  THEN
    CREATE TABLE utils.culture_hierarchy (
       culturecsid text,
       culture     text,
       parentcsid  text,
       nextcsid    text,
       culture_hierarchy text,
       csid_hierarchy text );

    CREATE INDEX uch_ccsid_ndx on utils.culture_hierarchy ( culturecsid );
    CREATE INDEX uch_cname_ndx on utils.culture_hierarchy ( culture );
  END IF;
END;
$$
LANGUAGE plpgsql
