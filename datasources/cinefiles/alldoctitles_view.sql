-- alldoctitles_view table used in CineFiles denorm
-- CRH 2/23/2014

create table cinefiles_denorm.alldoctitles_view as
select
--   h1.name objectCSID,
   cast(co.objectnumber as bigint) doc_id,
   cc.docdisplayname title
from
   hierarchy h1
   INNER JOIN collectionobjects_common co
      ON (h1.id = co.id AND h1.primarytype = 'CollectionObjectTenant50')
   INNER JOIN misc m
      ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
   INNER JOIN collectionobjects_cinefiles cc
      ON (co.id = cc.id)
WHERE (co.objectnumber ~ '^[0-9]+$' )
order by cast(co.objectnumber as bigint);

grant select on cinefiles_denorm.alldoctitles_view to group reporters;