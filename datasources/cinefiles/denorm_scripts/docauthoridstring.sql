-- docauthoridstring table used in cinefiles denorm
--
-- CRH 7/31/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 8/23/2014

DROP TABLE IF EXISTS cinefiles_denorm.docauthoridstringtmp;

CREATE TABLE cinefiles_denorm.docauthoridstringtmp AS
   SELECT
      cast(co.objectnumber as bigint) doc_id,
      cinefiles_denorm.finddocauthorids(co.objectnumber) docauthorids
   FROM
      collectionobjects_common co
      INNER JOIN misc m
         ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
   WHERE (co.objectnumber ~ '^[0-9]+$' )
     AND co.recordstatus='approved'
   ORDER BY cast(co.objectnumber AS bigint);

GRANT SELECT ON cinefiles_denorm.docauthoridstringtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.docauthoridstringtmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.docauthoridstring;
SELECT COUNT(1) FROM cinefiles_denorm.docauthoridstringtmp;

