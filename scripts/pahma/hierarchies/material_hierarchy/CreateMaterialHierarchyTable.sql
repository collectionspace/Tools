-- createMaterialHierarchyTable
-- 
-- A function to create an empty material_hierarchy table,
-- in the utils schema, if one does not already exist.
-- It does not drop or recreate any existing table.

CREATE OR REPLACE FUNCTION utils.createMaterialHierarchyTable() RETURNS void AS
$$
DECLARE
BEGIN
  IF NOT EXISTS ( SELECT relname
                  FROM pg_catalog.pg_class c
                       JOIN
                       pg_catalog.pg_namespace n
                       ON (n.oid = c.relnamespace)
               WHERE c.relname = 'material_hierarchy'
                 AND n.nspname = 'utils' )
  THEN
    CREATE TABLE utils.material_hierarchy (
       materialcsid text,
       material     text,
       parentcsid   text,
       nextcsid     text,
       material_hierarchy text,
       csid_hierarchy     text );

    CREATE INDEX umh_mcsid_ndx on utils.material_hierarchy ( materialcsid );
    CREATE INDEX umh_mname_ndx on utils.material_hierarchy ( material );
  END IF;
END;
$$
LANGUAGE plpgsql
