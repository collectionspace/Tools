-- filmdoccount table used in CineFiles denorm
--
-- CRH 2/22/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 6/16/2014

DROP TABLE IF EXISTS cinefiles_denorm.filmdoccounttmp;

CREATE TABLE cinefiles_denorm.filmdoccounttmp AS
   SELECT
      wc.shortidentifier filmId, count(*) doccount
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
      WHERE (co.objectnumber ~ '^[0-9]+$' )
        AND ccf.item IS NOT NULL
        AND ccf.item <> ''
      GROUP BY wc.shortidentifier
      ORDER BY wc.shortidentifier;

GRANT SELECT ON cinefiles_denorm.filmdoccounttmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.filmdoccounttmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.filmdoccount;
SELECT COUNT(1) FROM cinefiles_denorm.filmdoccounttmp;

