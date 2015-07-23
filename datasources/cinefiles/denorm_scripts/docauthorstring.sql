-- docauthorstring table used in cinefiles denorm
--
-- CRH 2/22/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 6/16/2014

DROP TABLE IF EXISTS cinefiles_denorm.docauthorstringtmp;

CREATE TABLE cinefiles_denorm.docauthorstringtmp as
   SELECT
      cast(co.objectnumber as bigint) doc_id,
      cinefiles_denorm.finddocauthors(co.objectnumber) docauthors
   FROM
      collectionobjects_common co
      INNER JOIN misc m
         ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
   WHERE (co.objectnumber ~ '^[0-9]+$' ) AND co.recordstatus='approved'
   ORDER BY cast(co.objectnumber as bigint);

GRANT SELECT ON cinefiles_denorm.docauthorstringtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.docauthorstringtmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.docauthorstring;
SELECT COUNT(1) FROM cinefiles_denorm.docauthorstringtmp;

