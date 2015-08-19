-- refreshCultureHierarchyTable
--
--  A function to keep the culture_hierarchy table up to date.
--  It is called from a nightly cron job

CREATE OR REPLACE FUNCTION utils.refreshCultureHierarchyTable() RETURNS void
AS $$
   insert into utils.refresh_log (msg) values ( 'Creating culture_hierarchy table' );
   select utils.createCultureHierarchyTable();

   insert into utils.refresh_log (msg) values ( 'Populating culture_hierarchy table' );
   select utils.populateCultureHierarchyTable();

   insert into utils.refresh_log (msg) values ( 'Updating culture_hierarchy table' );
   select utils.updateCultureHierarchyTable();

   insert into utils.refresh_log (msg) values ( 'All done' );
$$
LANGUAGE sql
