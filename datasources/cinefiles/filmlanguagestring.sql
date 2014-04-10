-- filmlanguagestring table used in cinefiles denorm
-- CRH 2/22/2014

create table cinefiles_denorm.filmlanguagestring as
SELECT
   wc.shortidentifier filmId, 
   cinefiles_denorm.findfilmlanguages(wc.shortidentifier) filmlanguages
FROM works_common wc
INNER JOIN misc m
   ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
-- WHERE cinefiles_denorm.findfilmlanguages(wc.shortidentifier) is not null
ORDER BY wc.shortidentifier;

grant select on cinefiles_denorm.filmlanguagestring to group reporters;