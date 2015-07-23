-- filmlanguagestring table used in cinefiles denorm
--
-- CRH 2/22/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 8/3/2014

DROP TABLE IF EXISTS cinefiles_denorm.filmlanguagestringtmp;

CREATE TABLE cinefiles_denorm.filmlanguagestringtmp AS
   SELECT
      wc.shortidentifier filmId,
      cinefiles_denorm.findfilmlanguages(wc.shortidentifier) filmlanguages
   FROM
      works_common wc
      INNER JOIN misc m
         ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
   -- WHERE cinefiles_denorm.findfilmlanguages(wc.shortidentifier) IS NOT NULL
   ORDER BY wc.shortidentifier;

GRANT SELECT ON cinefiles_denorm.filmlanguagestringtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.filmlanguagestringtmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.filmlanguagestring;
SELECT COUNT(1) FROM cinefiles_denorm.filmlanguagestringtmp;

