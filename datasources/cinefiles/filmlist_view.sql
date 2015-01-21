-- filmlist_view.sql, used in cinefiles_denorm
-- gets concatenated strings for repeating information insteaad of cartesian products
-- CRH 2/23/2014
-- CRH 7/31/2014 adding production company identifiers and updatedat for Mediatrope

-- drop table cinefiles_denorm.filmlist_view

create table cinefiles_denorm.filmlist_view as
SELECT
--   h1.name filmCSID,
   wc.shortidentifier film_id,
   fdids.filmdirectorids name_id,
   fdc.doccount doc_count,
   cinefiles_denorm.concat_worktitles(wc.shortidentifier) filmtitle,
   fcs.filmcountries country,
--   fys.filmyears filmyear,  need to allow for cartesian product to support numeric between search on year
   cast(sdg.dateearliestsingleyear as int) filmYear,
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
   LEFT OUTER JOIN cinefiles_denorm.filmdirectorstring fds on (wc.shortidentifier=fds.filmid)
   LEFT OUTER JOIN cinefiles_denorm.filmdirectoridstring fdids on (wc.shortidentifier=fdids.filmid)
   LEFT OUTER JOIN cinefiles_denorm.filmcountrystring fcs on (wc.shortidentifier=fcs.filmid)
--   LEFT OUTER JOIN cinefiles_denorm.filmyearstring fys on (wc.shortidentifier=fys.filmid)
   LEFT OUTER JOIN hierarchy h4
      ON ( h4.parentid = h1.id AND h4.name = 'works_common:workDateGroupList') 
   LEFT OUTER JOIN structureddategroup sdg
      ON ( h4.id = sdg.id )
   LEFT OUTER JOIN cinefiles_denorm.filmlanguagestring fls on (wc.shortidentifier=fls.filmid)
   LEFT OUTER JOIN cinefiles_denorm.filmsubjectstring fss on (wc.shortidentifier=fss.filmid)
   LEFT OUTER JOIN cinefiles_denorm.filmgenrestring fgs on (wc.shortidentifier=fgs.filmid)
   LEFT OUTER JOIN cinefiles_denorm.filmtitlestring fts on (wc.shortidentifier=fts.filmid)
   LEFT OUTER JOIN cinefiles_denorm.filmprodcostring fps on (wc.shortidentifier=fps.filmid)
   LEFT OUTER JOIN cinefiles_denorm.filmdoccount fdc on (wc.shortidentifier=fdc.filmid)
   LEFT OUTER JOIN cinefiles_denorm.filmprodcoidstring fpids on (wc.shortidentifier=fpids.filmid) 
   INNER JOIN collectionspace_core core on wc.id=core.id  
where fdc.doccount is not null
order by wc.shortidentifier;

grant select on cinefiles_denorm.filmlist_view to group reporters;
grant select on cinefiles_denorm.filmlist_view to group cinereaders;