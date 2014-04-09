-- docnamesubjectcitation table used in cinefiles denorm in document citation function doc_detail_summary.sql
-- CRH 3/17/2014
-- 4/7/2014 using concat_personname function

create table cinefiles_denorm.docnamesubjectcitation as
SELECT
--   h1.name objectCSID,
   cast(co.objectnumber as bigint) doc_id,
   case 
      when ccn.item like '%orgauthorities%'
        then trim(trailing ', ' from replace(replace(concat_ws(', ', cinefiles_denorm.getdispl(ccn.item), ocf.foundingcity, ocf.foundingcity, cinefiles_denorm.getdispl(oc.foundingplace)), ', , , ', ', '), ', , ', ', '))       
      else
        cinefiles_denorm.concat_personname(cinefiles_denorm.getshortid(ccn.item))     
   end as subjcitation
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
   left outer join organizations_common oc on (ccn.item=oc.refname)
   left outer join organizations_cinefiles ocf on (oc.id=ocf.id)
   left outer join persons_common pc on (ccn.item=pc.refname)
   left outer join persons_cinefiles pcf on (pc.id=pcf.id)
WHERE (co.objectnumber ~ '^[0-9]+$' ) and ccn.item is not null and ccn.item <> ''
ORDER BY cast(co.objectnumber as bigint);

grant select on cinefiles_denorm.docnamesubjectcitation to group reporters;