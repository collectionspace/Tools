drop index if exists cinefiles_denorm.persontermgroup_idx;

create index persontermgroup_idx
   on cinefiles_denorm.persontermgroup(id);

drop index if exists cinefiles_denorm.persontermgroup_termdisplayname_idx;

create index persontermgroup_termdisplayname_idx
   on cinefiles_denorm.persontermgroup(termdisplayname);

drop index if exists cinefiles_denorm.unaccenteddoctitle_idx;

create index unaccenteddoctitle_idx
   on cinefiles_denorm.doclist_view(cinefiles_denorm.lowernoaccent(doctitle));

drop index if exists cinefiles_denorm.unaccenteddocsource_idx;

create index unaccenteddocsource_idx
   on cinefiles_denorm.doclist_view(cinefiles_denorm.lowernoaccent(source));

drop index if exists cinefiles_denorm.unaccenteddocauthor_idx;

create index unaccenteddocauthor_idx
   on cinefiles_denorm.doclist_view(cinefiles_denorm.lowernoaccent(author));

drop index if exists cinefiles_denorm.unaccenteddocsubject_idx;

create index unaccenteddocsubject_idx
   on cinefiles_denorm.doclist_view(cinefiles_denorm.lowernoaccent(docsubject));

drop index if exists cinefiles_denorm.unaccenteddocnamesubject_idx;

create index unaccenteddocnamesubject_idx
   on cinefiles_denorm.doclist_view(cinefiles_denorm.lowernoaccent(docnamesubject));

drop index if exists cinefiles_denorm.unaccentedfilmtitle_idx;

create index unaccentedfilmtitle_idx
   on cinefiles_denorm.filmlist_view(cinefiles_denorm.lowernoaccent(filmtitle));

drop index if exists cinefiles_denorm.unaccentedprodco_idx;

create index unaccentedprodco_idx
   on cinefiles_denorm.filmlist_view(cinefiles_denorm.lowernoaccent(prodco));

drop index if exists cinefiles_denorm.unaccenteddirector_idx;

create index unaccenteddirector_idx
   on cinefiles_denorm.filmlist_view(cinefiles_denorm.lowernoaccent(director));

drop index if exists cinefiles_denorm.unaccentedfilmsubject_idx;

create index unaccentedfilmsubject_idx
   on cinefiles_denorm.filmlist_view(cinefiles_denorm.lowernoaccent(subject));

