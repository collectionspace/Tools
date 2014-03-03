-- filmprodcostring table used in cinefiles denorm
-- CRH 2/22/2014

create table cinefiles_denorm.filmprodcostring as
SELECT
   wc.shortidentifier filmId, 
   cinefiles_denorm.findfilmprodcos(wc.shortidentifier) filmprodcos
FROM works_common wc
INNER JOIN misc m
   ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
-- WHERE cinefiles_denorm.findfilmprodcos(wc.shortidentifier) is not null
ORDER BY wc.shortidentifier;

grant select on cinefiles_denorm.filmprodcostring to group reporters;