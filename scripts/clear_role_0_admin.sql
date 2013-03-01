-- clear_role_0_admin.sql

-- A PostgreSQL-specific SQL script to update older authentication and
-- authorization data (roles, permissions ...), allowing that data
-- to be migrated to CollectionSpace versions 3.2.1 and higher.

-- This script performs two actions within the 'cspace' database:
--
-- 1. Removing entries associated with a former notion of a "super"
--    administrator. This makes room for those entries to be replaced
--    with an "all tenants manager" role, with more limited permissions,
--    by running 'ant import' in a more recent CollectionSpace system.
--
-- 2. Adding a 'disabled' column to the 'tenants' table. This column
--    is used in newer versions of CollectionSpace to facilitate
--    selective disabling of tenants.

-- To identify whether you have an older 'cspace' database,
-- and will thus need to run this script when migrating your
-- users, roles, etc. to CollectionSpace 3.2.1 or higher systems,
-- run the following query in the 'cspace' database.
--
-- E.g. at the 'psql' command prompt, connect to the 'cspace'
-- database, then run the SELECT command which follows:
--
--   \c cspace
--   select * from roles where csid='0';
--
-- If you have an older 'cspace' database, this query will return
-- a row with a displayname of 'ADMINISTRATOR'.  (Newer 'cspace'
-- databases that don't require updating, will instead return a
-- row with a displayname of 'ALL_TENANTS_MANAGER'.)

-- If you have an older 'cspace' database, you can migrate your
-- users, roles, etc. to a v3.2.1 or higher CollectionSpace system
-- in this way:
--
-- 1. Follow the instructions in the installation guide appropriate
--    for your system (or run the appropriate installer application,
--    if available) to set up a newer CollectionSpace system (version
--    3.2.1 or higher), and to ensure that it is working properly.
--
-- 2. Shut down that newer CollectionSpace system, if it is running.
--
-- 3. Wipe and then create an empty 'cspace' database on your newer
--    system, by running the copy of the 'init_cspace_db.sql' script
--    that has been deployed to your Tomcat server folder.
--
--    E.g. on a Linux or other Unix-like system (enter your 'postgres'
--    database user password when prompted):
--
--    cd $CATALINA_HOME/cspace/services/db/postgresql
--    psql -U postgres -f init_cspace_db.sql
--
--    WARNING: Any existing data in the 'cspace' database will be deleted.
--    Be sure to run this script against your *newer*, freshly-installed
--    CollectionSpace system, rather than against an older system that
--    contains 'real' data. (If you wish to be further cautious, see the step
--    below for instructions on first making a backup of your older system's
--    data, just in case, by performing step 4 prior to step 3.)
--
-- 4. Export your 'cspace' database from your older system via 'pg_dump'
--    using a command similar to the following. (Enter your 'cspace'
--    database user password when prompted.)
--
--    pg_dump -U cspace cspace > my_cspace_database_dump_file.sql
--
-- 5. On your newer system, import the contents of your older 'cspace'
--    database by executing the commands in your export file.
--    (Enter your 'cspace' database user password when prompted.)
--
--    psql -U cspace -d cspace -f my_cspace_database_dump_file.sql
--
-- 6. Run this script, 'clear_role_0_admin.sql', to update your
--    newly-imported 'cspace' database. (Enter your 'cspace' database
--    user password when prompted.)
--
--    psql -U cspace -d cspace -a -f clear_role_0_admin.sql
--
-- 7. From the root of the CollectionSpace services source code tree,
--    run 'ant import'.
--
-- 8. Start your CollectionSpace system.
--
-- 9. Verify that you can log in, and that you can view and create records.

-- #########################################################################

-- Delete the CSpace role
delete from roles where csid='0';

-- Delete the CSpace role permission associations
delete from permissions_roles where role_id='0';

-- Delete the Spring role permission associations
delete from acl_entry USING acl_sid WHERE acl_entry.sid=acl_sid.id AND acl_sid.sid='ROLE_0_ADMINISTRATOR';

-- Delete the Spring role 
delete from acl_sid WHERE sid='ROLE_0_ADMINISTRATOR';

-- Add the 'disabled' column to the 'tenants' table, if not already present
DO $$ 
    BEGIN
        BEGIN
            ALTER TABLE tenants ADD COLUMN disabled boolean;
        EXCEPTION
            WHEN duplicate_column THEN RAISE NOTICE '[INFO] Column "disabled" already exists in "tenants" table.';
        END;
    END;
$$;

-- Set the 'disabled' flag to 'false' for any tenant
-- which has no value for that flag already present
UPDATE tenants SET disabled='false' WHERE disabled IS NULL;
