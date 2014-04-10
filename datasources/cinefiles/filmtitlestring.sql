-- filmtitlestring table used in cinefiles denorm
-- CRH 2/22/2014

create table cinefiles_denorm.filmtitlestring as
SELECT
   wc.shortidentifier filmId, 
   cinefiles_denorm.findfilmtitles(wc.shortidentifier) filmtitles
FROM works_common wc
INNER JOIN misc m
   ON (wc.id = m.id AND m.lifecyclestate <> 'deleted')
-- WHERE cinefiles_denorm.findfilmtitles(wc.shortidentifier) is not null
ORDER BY wc.shortidentifier;

grant select on cinefiles_denorm.filmtitlestring to group reporters;