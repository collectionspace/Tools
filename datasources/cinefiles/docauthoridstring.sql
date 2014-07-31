-- docauthoridstring table used in cinefiles denorm
-- CRH 7/31/2014

create table cinefiles_denorm.docauthoridstring as
SELECT
   cast(co.objectnumber as bigint) doc_id, 
   cinefiles_denorm.finddocauthorids(co.objectnumber) docauthorids
FROM collectionobjects_common co
INNER JOIN misc m
   ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
WHERE (co.objectnumber ~ '^[0-9]+$' ) and co.recordstatus='approved'
order by cast(co.objectnumber as bigint);

grant select on cinefiles_denorm.docauthoridstring to group reporters;