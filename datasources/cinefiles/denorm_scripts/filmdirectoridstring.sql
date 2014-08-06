-- filmdirectoridstring table used in cinefiles denorm
--
-- CRH 2/27/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 8/3/2014

DROP TABLE IF EXISTS cinefiles_denorm.filmdirectoridstringtmp;

CREATE TABLE cinefiles_denorm.filmdirectoridstringtmp AS
   SELECT
      wc.shortidentifier filmId,
      cinefiles_denorm.findfilmdirectorids(wc.shortidentifier) filmdirectorids
   FROM
      works_common wc
      INNER JOIN misc m
         ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
   -- WHERE cinefiles_denorm.findfilmdirectorids(wc.shortidentifier) IS NOT NULL
   ORDER BY wc.shortidentifier;

GRANT SELECT ON cinefiles_denorm.filmdirectoridstringtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.filmdirectoridstringtmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.filmdirectoridstring;
SELECT COUNT(1) FROM cinefiles_denorm.filmdirectoridstringtmp;
