-- filmgenres table used by CineFiles denorm
-- CRH 2/23/2014

create table cinefiles_denorm.filmgenres as
SELECT
--   h1.name filmCSID,
   wc.shortidentifier film_id,
   cinefiles_denorm.getshortid(wcg.item) genre_id,
   'na' entered,
   'na' modified,
   'na' entered_by,
   'na' verified_by,
   'na' src_id,
   'na' note
FROM
   hierarchy h1
   INNER JOIN works_common wc
      ON ( h1.id = wc.id AND h1.primarytype = 'WorkitemTenant50' )
   INNER JOIN misc m
      ON ( wc.id = m.id AND m.lifecyclestate <> 'deleted' )
   LEFT OUTER JOIN works_cinefiles_genres wcg
      ON ( wc.id = wcg.id)
order by film_id, wcg.pos; 

grant select on cinefiles_denorm.filmgenres to group reporters;