-- docauthorstring table used in cinefiles denorm
-- CRH 3/1/2014

create table cinefiles_denorm.docauthorstring as
SELECT
   cast(co.objectnumber as bigint) doc_id, 
   cinefiles_denorm.finddocauthors(co.objectnumber) docauthors
FROM collectionobjects_common co
INNER JOIN misc m
   ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
WHERE (co.objectnumber ~ '^[0-9]+$' ) and co.recordstatus='approved'
order by cast(co.objectnumber as bigint);

grant select on cinefiles_denorm.docauthorstring to group reporters;