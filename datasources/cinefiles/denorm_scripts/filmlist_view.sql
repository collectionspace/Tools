-- filmlist_view.sql, used in cinefiles_denorm
--
-- CRH 2/23/2014
-- CRH 7/31/2014 adding production company identifiers and updatedat for Mediatrope
--
-- gets concatenated strings for repeating information instead
-- of cartesian products
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified, GLJ 8/2/2014

DROP TABLE IF EXISTS cinefiles_denorm.filmlist_viewtmp;

CREATE TABLE cinefiles_denorm.filmlist_viewtmp AS
   SELECT
      -- h1.name filmCSID,
      wc.shortidentifier film_id,
      fdids.filmdirectorids name_id,
      fdc.doccount doc_count,
      cinefiles_denorm.concat_worktitles(wc.shortidentifier) filmtitle,
      fcs.filmcountries country,
      -- fys.filmyears filmyear, need to allow for cartesian product
      -- to support numeric between search ON year
      cast(sdg.dateearliestsingleyear AS int) filmYear,
      fds.filmdirectors director,
      fls.filmlanguages filmlanguage,
      fps.filmprodcos prodco,
      fss.filmsubjects subject,
      fgs.filmgenres genre,
      fts.filmtitles title,
      fpids.filmprodcoids prodco_id,
      core.updatedat
   FROM
      hierarchy h1
      INNER JOIN works_common wc
         ON ( h1.id = wc.id AND h1.primarytype = 'WorkitemTenant50' )
      INNER JOIN misc m
         ON ( wc.id = m.id AND m.lifecyclestate <> 'deleted' )
      LEFT OUTER JOIN cinefiles_denorm.filmdirectorstring fds
         ON (wc.shortidentifier=fds.filmid)
      LEFT OUTER JOIN cinefiles_denorm.filmdirectoridstring fdids
         ON (wc.shortidentifier=fdids.filmid)
      LEFT OUTER JOIN cinefiles_denorm.filmcountrystring fcs
         ON (wc.shortidentifier=fcs.filmid)
      -- LEFT OUTER JOIN cinefiles_denorm.filmyearstring fys
      --    ON (wc.shortidentifier=fys.filmid)
      LEFT OUTER JOIN hierarchy h4
         ON ( h4.parentid = h1.id
              AND h4.name = 'works_common:workDateGroupList')
      LEFT OUTER JOIN structureddategroup sdg
         ON ( h4.id = sdg.id )
      LEFT OUTER JOIN cinefiles_denorm.filmlanguagestring fls
         ON (wc.shortidentifier=fls.filmid)
      LEFT OUTER JOIN cinefiles_denorm.filmsubjectstring fss
         ON (wc.shortidentifier=fss.filmid)
      LEFT OUTER JOIN cinefiles_denorm.filmgenrestring fgs
         ON (wc.shortidentifier=fgs.filmid)
      LEFT OUTER JOIN cinefiles_denorm.filmtitlestring fts
         ON (wc.shortidentifier=fts.filmid)
      LEFT OUTER JOIN cinefiles_denorm.filmprodcostring fps
         ON (wc.shortidentifier=fps.filmid)
      LEFT OUTER JOIN cinefiles_denorm.filmdoccount fdc
         ON (wc.shortidentifier=fdc.filmid)
      LEFT OUTER JOIN cinefiles_denorm.filmprodcoidstring fpids
         ON (wc.shortidentifier=fpids.filmid)
      INNER JOIN collectionspace_core core on wc.id=core.id
   WHERE fdc.doccount IS NOT NULL
   ORDER BY wc.shortidentifier;

GRANT SELECT ON cinefiles_denorm.filmlist_viewtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.filmlist_viewtmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.filmlist_view;
SELECT COUNT(1) FROM cinefiles_denorm.filmlist_viewtmp;

