-- filmdirectorstring table used in cinefiles denorm
-- CRH 2/22/2014

-- drop table cinefiles_denorm.filmdirectorstring

create table cinefiles_denorm.filmdirectorstring as
SELECT
   wc.shortidentifier filmId, 
   cinefiles_denorm.findfilmdirectors(wc.shortidentifier) filmdirectors
FROM works_common wc
INNER JOIN misc m
   ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
-- WHERE cinefiles_denorm.finddirectors(wc.shortidentifier) is not null
ORDER BY wc.shortidentifier;

grant select on cinefiles_denorm.filmdirectorstring to group reporters;