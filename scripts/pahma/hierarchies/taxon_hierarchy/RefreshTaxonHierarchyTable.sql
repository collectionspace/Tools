-- refreshTaxonHierarchyTable
--
--  A function to keep the taxon_hierarchy table up to date.
--  It is called from a nightly cron job

CREATE OR REPLACE FUNCTION utils.refreshTaxonHierarchyTable() RETURNS void
AS $$
   insert into utils.refresh_log (msg) values ( 'Creating taxon_hierarchy table' );
   select utils.createTaxonHierarchyTable();

   insert into utils.refresh_log (msg) values ( 'Populating taxon_hierarchy table' );
   select utils.populateTaxonHierarchyTable();

   insert into utils.refresh_log (msg) values ( 'Updating taxon_hierarchy table' );
   select utils.updateTaxonHierarchyTable();

   insert into utils.refresh_log (msg) values ( 'All done' );
$$
LANGUAGE sql
