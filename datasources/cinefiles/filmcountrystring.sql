-- filmcountrystring table used in cinefiles denorm
-- CRH 2/22/2014

-- drop table cinefiles_denorm.filmcountrystring;

create table cinefiles_denorm.filmcountrystring as
SELECT
   wc.shortidentifier filmId, 
   cinefiles_denorm.findfilmcountries(wc.shortidentifier) filmcountries
FROM works_common wc
INNER JOIN misc m
   ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
-- WHERE cinefiles_denorm.findfilmcountries(wc.shortidentifier) is not null
ORDER BY wc.shortidentifier;

grant select on cinefiles_denorm.filmcountrystring to group reporters;