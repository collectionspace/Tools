-- filmprodcoidstring table used in cinefiles denorm
--
-- CRH 7/31/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 8/3/2014

DROP TABLE IF EXISTS cinefiles_denorm.filmprodcoidstringtmp;

CREATE TABLE cinefiles_denorm.filmprodcoidstringtmp AS
   SELECT
      wc.shortidentifier filmId, 
      cinefiles_denorm.findfilmprodcoids(wc.shortidentifier) filmprodcoids
   FROM works_common wc
   INNER JOIN misc m
      ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
   -- WHERE cinefiles_denorm.findfilmprodcos(wc.shortidentifier) is not null
   ORDER BY wc.shortidentifier;

GRANT SELECT ON cinefiles_denorm.filmprodcoidstringtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.filmprodcoidstringtmp TO GROUP cinereaders;

SELECT  COUNT(1) from cinefiles_denorm.filmprodcoidstring;
SELECT  COUNT(1) from cinefiles_denorm.filmprodcoidstringtmp;
