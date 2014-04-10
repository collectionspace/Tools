-- filmsubjectstring table used in cinefiles denorm
-- might be a substitute for filmgenres table/view as well
-- CRH 2/22/2014

-- drop table cinefiles_denorm.filmsubjectstring

create table cinefiles_denorm.filmsubjectstring as
SELECT
   wc.shortidentifier filmId, 
   cinefiles_denorm.findfilmsubjects(wc.shortidentifier) filmsubjects
FROM works_common wc
INNER JOIN misc m
   ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
-- WHERE cinefiles_denorm.findsubjects(wc.shortidentifier) is not null
ORDER BY wc.shortidentifier;

grant select on cinefiles_denorm.filmsubjectstring to group reporters;