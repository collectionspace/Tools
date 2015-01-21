-- filmdocs table used by CineFiles denorm
--
-- CRH 2/23/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 8/3/2014

DROP TABLE IF EXISTS cinefiles_denorm.filmdocstmp;

CREATE TABLE cinefiles_denorm.filmdocstmp AS
   SELECT
      wc.shortidentifier film_id,
      cast(co.objectnumber AS bigint) doc_id,
      'not used'::char(8) AS entered,
      'not used'::char(8) AS modified,
      'not used'::char(8) AS entered_by,
      'not used'::char(8) AS verified_by,
      'not used'::char(8) AS note
   FROM
      hierarchy h1
      INNER JOIN collectionobjects_common co
         ON (h1.id = co.id AND h1.primarytype = 'CollectionObjectTenant50')
      INNER JOIN misc m
         ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
      INNER JOIN collectionobjects_cinefiles_filmsubjects ccf
         ON (co.id = ccf.id)
      INNER JOIN works_common wc
         ON (wc.refname=ccf.item)
   WHERE (co.objectnumber ~ '^[0-9]+$')
     AND ccf.item IS NOT NULL
     AND ccf.item <> ''
   ORDER BY wc.shortidentifier, cast(co.objectnumber AS bigint);

GRANT SELECT ON cinefiles_denorm.filmdocstmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.filmdocstmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.filmdocs;
SELECT COUNT(1) FROM cinefiles_denorm.filmdocstmp;

