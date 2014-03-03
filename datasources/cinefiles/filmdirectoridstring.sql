-- filmdirectoridstring table used in cinefiles denorm
-- CRH 2/27/2014

-- drop table cinefiles_denorm.filmdirectoridstring

create table cinefiles_denorm.filmdirectoridstring as
SELECT
   wc.shortidentifier filmId, 
   cinefiles_denorm.findfilmdirectorids(wc.shortidentifier) filmdirectorids
FROM works_common wc
INNER JOIN misc m
   ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
-- WHERE cinefiles_denorm.findfilmdirectorids(wc.shortidentifier) is not null
ORDER BY wc.shortidentifier;

grant select on cinefiles_denorm.filmdirectoridstring to group reporters;