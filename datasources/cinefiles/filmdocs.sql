-- filmdocs table used by CineFiles denorm
-- CRH 2/23/2014

create table cinefiles_denorm.filmdocs as
SELECT
   wc.shortidentifier film_id,
   cast(co.objectnumber as bigint) doc_id,
   'not used' as entered,
   'not used' as modified,
   'not used' as entered_by,
   'not used' as verified_by,
   'not used' as note
FROM
   hierarchy h1
   INNER JOIN collectionobjects_common co
      ON (h1.id = co.id AND h1.primarytype = 'CollectionObjectTenant50')
   INNER JOIN misc m
      ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
   INNER JOIN collectionobjects_cinefiles_filmsubjects ccf
      ON (co.id = ccf.id)
   INNER JOIN works_common wc on (wc.refname=ccf.item)
WHERE (co.objectnumber ~ '^[0-9]+$' ) and ccf.item is not null and ccf.item <> ''
order by wc.shortidentifier, cast(co.objectnumber as bigint);

grant select on cinefiles_denorm.filmdocs to group reporters;
grant select on cinefiles_denorm.filmdocs to group cinereaders;