-- allfilmtitles_view table used in CineFiles denorm
-- CRH 2/23/2014

create table cinefiles_denorm.allfilmtitles_view as
SELECT
--   h1.name filmCSID,
   wc.shortidentifier film_id,
   wtg.termdisplayname title
FROM
   hierarchy h1
   INNER JOIN works_common wc
      ON ( h1.id = wc.id AND h1.primarytype = 'WorkitemTenant50' )
   INNER JOIN misc m
      ON ( wc.id = m.id AND m.lifecyclestate <> 'deleted' )
   LEFT OUTER JOIN hierarchy h3
      ON ( h3.parentid = h1.id AND h3.primarytype = 'workTermGroup')
   LEFT OUTER JOIN worktermgroup wtg
      ON ( h3.id = wtg.id)
ORDER BY wc.shortidentifier, h3.pos;

grant select on cinefiles_denorm.allfilmtitles_view to group reporters;