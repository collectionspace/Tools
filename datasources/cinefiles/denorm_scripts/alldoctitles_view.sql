-- alldoctitles_view table used in CineFiles denorm
--
-- CRH 2/23/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
-- 
-- Modified GLJ 8/3/2014

DROP TABLE IF EXISTS cinefiles_denorm.alldoctitles_viewtmp;

CREATE TABLE cinefiles_denorm.alldoctitles_viewtmp AS
   SELECT
      -- h1.name objectCSID,
      cast(co.objectnumber AS bigint) doc_id,
      cc.docdisplayname title
   FROM
      hierarchy h1
      INNER JOIN collectionobjects_common co
         ON (h1.id = co.id AND h1.primarytype = 'CollectionObjectTenant50')
      INNER JOIN misc m
         ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
      INNER JOIN collectionobjects_cinefiles cc
         ON (co.id = cc.id)
   WHERE (co.objectnumber ~ '^[0-9]+$' )
   ORDER BY cast(co.objectnumber AS bigint);

GRANT SELECT ON cinefiles_denorm.alldoctitles_viewtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.alldoctitles_viewtmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.alldoctitles_view;
SELECT COUNT(1) FROM cinefiles_denorm.alldoctitles_viewtmp;

