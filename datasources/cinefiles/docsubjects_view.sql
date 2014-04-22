-- docsubjects_view table, used in CineFiles denorm
-- CRH 2/23/2014

create table cinefiles_denorm.docsubjects_view as
SELECT
--   h1.name objectCSID,
   cast(co.objectnumber as bigint) doc_id,
   cinefiles_denorm.getdispl(ccn.item) subj
FROM
   hierarchy h1
   INNER JOIN collectionobjects_common co
      ON (h1.id = co.id AND h1.primarytype = 'CollectionObjectTenant50')
   INNER JOIN misc m
      ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
   INNER JOIN collectionobjects_cinefiles cc
      ON (co.id = cc.id)
   INNER JOIN collectionobjects_cinefiles_namesubjects ccn
      ON (co.id = ccn.id)
WHERE (co.objectnumber ~ '^[0-9]+$' ) and ccn.item is not null and ccn.item <> ''
union
SELECT
--   h1.name objectCSID,
   cast(co.objectnumber as bigint) doc_id,
   cinefiles_denorm.getdispl(ccd.item) subj
FROM
   hierarchy h1
   INNER JOIN collectionobjects_common co
      ON (h1.id = co.id AND h1.primarytype = 'CollectionObjectTenant50')
   INNER JOIN misc m
      ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
   INNER JOIN collectionobjects_cinefiles cc
      ON (co.id = cc.id)
   INNER JOIN collectionobjects_cinefiles_docsubjects ccd
      ON (co.id = ccd.id)
WHERE (co.objectnumber ~ '^[0-9]+$' ) and ccd.item is not null and ccd.item <> ''
ORDER BY doc_id;

grant select on cinefiles_denorm.docsubjects_view to group reporters;