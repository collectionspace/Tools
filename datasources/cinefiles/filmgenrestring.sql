-- filmgenrestring table used in cinefiles denorm
-- might be a substitute for filmgenres table/view as well
-- CRH 2/22/2014

-- drop table cinefiles_denorm.filmgenrestring

create table cinefiles_denorm.filmgenrestring as
SELECT
   wc.shortidentifier filmId, 
   cinefiles_denorm.findfilmgenres(wc.shortidentifier) filmgenres
FROM works_common wc
INNER JOIN misc m
   ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
WHERE cinefiles_denorm.findfilmgenres(wc.shortidentifier) is not null
ORDER BY wc.shortidentifier;
	
grant select on cinefiles_denorm.filmgenrestring to group reporters;