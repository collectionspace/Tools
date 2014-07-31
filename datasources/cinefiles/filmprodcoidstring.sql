-- filmprodcoidstring table used in cinefiles denorm
-- CRH 7/31/2014

create table cinefiles_denorm.filmprodcoidstring as
SELECT
   wc.shortidentifier filmId, 
   cinefiles_denorm.findfilmprodcoids(wc.shortidentifier) filmprodcoids
FROM works_common wc
INNER JOIN misc m
   ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
-- WHERE cinefiles_denorm.findfilmprodcos(wc.shortidentifier) is not null
ORDER BY wc.shortidentifier;

grant select on cinefiles_denorm.filmprodcoidstring to group reporters;