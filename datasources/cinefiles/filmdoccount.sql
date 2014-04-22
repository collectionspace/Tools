create table cinefiles_denorm.filmdoccount as
   SELECT
	   wc.shortidentifier filmId, count(*) doccount
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
	group by wc.shortidentifier
	order by wc.shortidentifier;
	
grant select on cinefiles_denorm.filmdoccount to group reporters;