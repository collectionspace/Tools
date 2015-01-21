-- filmgenres table used by CineFiles denorm
--
-- CRH 2/23/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 8/3/2014

DROP TABLE IF EXISTS cinefiles_denorm.filmgenrestmp;

CREATE TABLE cinefiles_denorm.filmgenrestmp AS
   SELECT
      -- h1.name filmCSID,
      wc.shortidentifier film_id,
      cinefiles_denorm.getshortid(wcg.item) genre_id,
      'na'::char(2) entered,
      'na'::char(2) modified,
      'na'::char(2) entered_by,
      'na'::char(2) verified_by,
      'na'::char(2) src_id,
      'na'::char(2) note
   FROM
      hierarchy h1
      INNER JOIN works_common wc
         ON (h1.id = wc.id AND h1.primarytype = 'WorkitemTenant50' )
      INNER JOIN misc m
         ON (wc.id = m.id AND m.lifecyclestate <> 'deleted' )
      LEFT OUTER JOIN works_cinefiles_genres wcg
         ON (wc.id = wcg.id)
   ORDER BY film_id, wcg.pos;

GRANT SELECT ON cinefiles_denorm.filmgenrestmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.filmgenrestmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.filmgenres;
SELECT COUNT(1) FROM cinefiles_denorm.filmgenrestmp;

