-- refreshMaterialHierarchyTable
--
--  A function to keep the material_hierarchy table up to date.
--  It is called from a nightly cron job

CREATE OR REPLACE FUNCTION utils.refreshMaterialHierarchyTable() RETURNS void
AS $$
   insert into utils.refresh_log (msg) values ( 'Creating material_hierarchy table' );
   select utils.createMaterialHierarchyTable();

   insert into utils.refresh_log (msg) values ( 'Populating material_hierarchy table' );
   select utils.populateMaterialHierarchyTable();

   insert into utils.refresh_log (msg) values ( 'Updating material_hierarchy table' );
   select utils.updateMaterialHierarchyTable();

   insert into utils.refresh_log (msg) values ( 'All done' );
$$
LANGUAGE sql
