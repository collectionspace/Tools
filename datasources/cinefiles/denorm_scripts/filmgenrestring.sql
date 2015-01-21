-- filmgenrestring table used in cinefiles denorm
--
-- might be a substitute for filmgenres table/view as well
--
-- CRH 2/22/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 8/3/2014

DROP TABLE IF EXISTS cinefiles_denorm.filmgenrestringtmp;

CREATE TABLE cinefiles_denorm.filmgenrestringtmp AS
   SELECT
      wc.shortidentifier filmId,
      cinefiles_denorm.findfilmgenres(wc.shortidentifier) filmgenres
   FROM
      works_common wc
      INNER JOIN misc m
         ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
   WHERE cinefiles_denorm.findfilmgenres(wc.shortidentifier) IS NOT NULL
   ORDER BY wc.shortidentifier;

GRANT SELECT ON cinefiles_denorm.filmgenrestringtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.filmgenrestringtmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.filmgenrestring;
SELECT COUNT(1) FROM cinefiles_denorm.filmgenrestringtmp;

