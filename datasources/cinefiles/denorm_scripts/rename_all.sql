-- rename_all  used in CineFiles denorm
-- 
-- Renames temporary tables after all have been successfully created.
-- Not called if any of the table creation scripts failed.
-- 
-- GLJ 6/16/2014

DROP TABLE IF EXISTS cinefiles_denorm.alldoctitles_view;
ALTER TABLE IF EXISTS cinefiles_denorm.alldoctitles_viewtmp
    RENAME TO alldoctitles_view; 

DROP TABLE IF EXISTS cinefiles_denorm.allfilmtitles_view;
ALTER TABLE IF EXISTS cinefiles_denorm.allfilmtitles_viewtmp
    RENAME TO allfilmtitles_view; 

DROP TABLE IF EXISTS cinefiles_denorm.docsubjects_view;
ALTER TABLE IF EXISTS cinefiles_denorm.docsubjects_viewtmp
    RENAME TO docsubjects_view; 

DROP TABLE IF EXISTS cinefiles_denorm.filmdoccount;
ALTER TABLE IF EXISTS cinefiles_denorm.filmdoccounttmp
    RENAME TO filmdoccount;

DROP TABLE IF EXISTS cinefiles_denorm.filmdocs;
ALTER TABLE IF EXISTS cinefiles_denorm.filmdocstmp
    RENAME TO filmdocs;

DROP TABLE IF EXISTS cinefiles_denorm.filmgenres;
ALTER TABLE IF EXISTS cinefiles_denorm.filmgenrestmp
    RENAME TO filmgenres;

DROP TABLE IF EXISTS cinefiles_denorm.docnamesubjectcitation;
ALTER TABLE IF EXISTS cinefiles_denorm.docnamesubjectcitationtmp
    RENAME TO docnamesubjectcitation;

DROP TABLE IF EXISTS cinefiles_denorm.docauthorstring;
ALTER TABLE IF EXISTS cinefiles_denorm.docauthorstringtmp
    RENAME TO docauthorstring;

DROP TABLE IF EXISTS cinefiles_denorm.doclanguagestring;
ALTER TABLE IF EXISTS cinefiles_denorm.doclanguagestringtmp
    RENAME TO doclanguagestring;

DROP TABLE IF EXISTS cinefiles_denorm.docnamesubjectstring;
ALTER TABLE IF EXISTS cinefiles_denorm.docnamesubjectstringtmp
    RENAME TO docnamesubjectstring;

DROP TABLE IF EXISTS cinefiles_denorm.docsubjectstring;
ALTER TABLE IF EXISTS cinefiles_denorm.docsubjectstringtmp
    RENAME TO docsubjectstring;

DROP TABLE IF EXISTS cinefiles_denorm.filmcountrystring;
ALTER TABLE IF EXISTS cinefiles_denorm.filmcountrystringtmp
    RENAME TO filmcountrystring;

DROP TABLE IF EXISTS cinefiles_denorm.filmdirectoridstring;
ALTER TABLE IF EXISTS cinefiles_denorm.filmdirectoridstringtmp
    RENAME TO filmdirectoridstring;

DROP TABLE IF EXISTS cinefiles_denorm.filmdirectorstring;
ALTER TABLE IF EXISTS cinefiles_denorm.filmdirectorstringtmp
    RENAME TO filmdirectorstring;

DROP TABLE IF EXISTS cinefiles_denorm.filmgenrestring;
ALTER TABLE IF EXISTS cinefiles_denorm.filmgenrestringtmp
    RENAME TO filmgenrestring;

DROP TABLE IF EXISTS cinefiles_denorm.filmlanguagestring;
ALTER TABLE IF EXISTS cinefiles_denorm.filmlanguagestringtmp
    RENAME TO filmlanguagestring;

DROP TABLE IF EXISTS cinefiles_denorm.filmprodcostring;
ALTER TABLE IF EXISTS cinefiles_denorm.filmprodcostringtmp
    RENAME TO filmprodcostring;

DROP TABLE IF EXISTS cinefiles_denorm.filmsubjectstring;
ALTER TABLE IF EXISTS cinefiles_denorm.filmsubjectstringtmp
    RENAME TO filmsubjectstring;

DROP TABLE IF EXISTS cinefiles_denorm.filmtitlestring;
ALTER TABLE IF EXISTS cinefiles_denorm.filmtitlestringtmp
    RENAME TO filmtitlestring;

DROP TABLE IF EXISTS cinefiles_denorm.doclist_view;
ALTER TABLE IF EXISTS cinefiles_denorm.doclist_viewtmp
    RENAME TO doclist_view;

DROP TABLE IF EXISTS cinefiles_denorm.filmlist_view;
ALTER TABLE IF EXISTS cinefiles_denorm.filmlist_viewtmp
    RENAME TO filmlist_view;

DROP TABLE IF EXISTS cinefiles_denorm.docauthoridstring;
ALTER TABLE IF EXISTS cinefiles_denorm.docauthoridstringtmp
    RENAME TO docauthoridstring;

DROP TABLE IF EXISTS cinefiles_denorm.filmprodcoidstring;
ALTER TABLE IF EXISTS cinefiles_denorm.filmprodcoidstringtmp
    RENAME TO filmprodcoidstring;

DROP TABLE IF EXISTS cinefiles_denorm.organizationlist;
ALTER TABLE IF EXISTS cinefiles_denorm.organizationlisttmp
    RENAME TO organizationlist;

DROP TABLE IF EXISTS cinefiles_denorm.personlist;
ALTER TABLE IF EXISTS cinefiles_denorm.personlisttmp
    RENAME TO personlist;

