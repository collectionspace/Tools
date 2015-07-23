-- docnamesubjectstring table used in cinefiles denorm
--
-- CRH 3/2/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 8/3/2014

DROP TABLE IF EXISTS cinefiles_denorm.docnamesubjectstringtmp;

CREATE TABLE cinefiles_denorm.docnamesubjectstringtmp AS
   SELECT
      cast(co.objectnumber as bigint) doc_id,
      cinefiles_denorm.finddocnamesubjects(co.objectnumber) docnamesubjects
   FROM
      collectionobjects_common co
      INNER JOIN misc m
         ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
   WHERE (co.objectnumber ~ '^[0-9]+$' ) AND co.recordstatus='approved'
   ORDER BY cast(co.objectnumber as bigint);

GRANT SELECT ON cinefiles_denorm.docnamesubjectstringtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.docnamesubjectstringtmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.docnamesubjectstring;
SELECT COUNT(1) FROM cinefiles_denorm.docnamesubjectstringtmp;

