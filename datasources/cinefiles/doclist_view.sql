-- doclist_view, used in CineFiles denorm as primary source for searching documents
-- CRH 2/23/2014
-- CRH 7/31/2014 adding doc author ids and updatedaat for Mediatrope

-- drop table cinefiles_denorm.doclist_view;

create table cinefiles_denorm.doclist_view as
select
--   h1.name objectCSID,
   cast(co.objectnumber as bigint) doc_id,
   cc.docdisplayname doctitle,
   cinefiles_denorm.getdispl(cc.doctype) doctype,
   co.numberofobjects pages,
   cc.pageinfo pg_info,
   cinefiles_denorm.getdispl(cc.source) source,
   cinefiles_denorm.getshortid(cc.source) src_id,
   das.docauthors author,
   daids.docauthorids as name_id,
   dls.doclanguages doclanguage,
   sdg.datedisplaydate pubdate, 
  case when (cc.accesscode is null or cc.accesscode = '') 
   then
   case when ocf.accesscode = 'PFA Staff Only' then 0
      when ocf.accesscode = 'In House Only' then 1
      when ocf.accesscode = 'Campus (UCB)' then 2
      when ocf.accesscode = 'Education (.edu)' then 3
      when ocf.accesscode = 'World' then 4
      when (cc.source is null or cc.source='') then 4
      else null
   end
   else
   case when cc.accesscode = 'PFA Staff Only' then 0
      when cc.accesscode = 'In House Only' then 1
      when cc.accesscode = 'Campus (UCB)' then 2
      when cc.accesscode = 'Education (.edu)' then 3
      when cc.accesscode = 'World' then 4
      else null
   end
  end as code,
   cc.hascastcr as cast_cr,
   cc.hastechcr as tech_cr,
   cc.hasboxinfo as bx_info, 
   cc.hasfilmog as filmog,
   cc.hasdistco as dist_co,
   cc.hasprodco as prod_co,  
   cc.hascostinfo as costinfo,
   cc.hasillust as illust,
   cc.hasbiblio as biblio,
   rg.referencenote docurl,
   sdg.dateearliestscalarvalue pubdatescalar,
   wag.webaddress srcUrl,
   dss.docsubjects docsubject,
   dnss.docnamesubjects docnamesubject,
   core.updatedat
from
   hierarchy h1
   INNER JOIN collectionobjects_common co
      ON (h1.id = co.id AND h1.primarytype = 'CollectionObjectTenant50')
   INNER JOIN misc m
      ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
   INNER JOIN collectionobjects_cinefiles cc
      ON (co.id = cc.id)
   LEFT OUTER JOIN cinefiles_denorm.doclanguagestring dls
      ON (cast(co.objectnumber as bigint) = dls.doc_id)
   LEFT OUTER JOIN cinefiles_denorm.docauthorstring das
      ON (cast(co.objectnumber as bigint) = das.doc_id)
   LEFT OUTER JOIN hierarchy h2
      ON (h2.parentid = co.id AND h2.name='collectionobjects_common:objectProductionDateGroupList' and h2.pos=0)
   LEFT OUTER JOIN structuredDateGroup sdg ON (h2.id = sdg.id)
   LEFT OUTER JOIN organizations_common oco ON (cc.source=oco.refname)
   LEFT OUTER JOIN organizations_cinefiles ocf on (oco.id=ocf.id)
   LEFT OUTER JOIN hierarchy h3
      ON (h3.parentid = co.id AND h3.primarytype = 'referenceGroup' and h3.pos=0)
   LEFT OUTER JOIN referencegroup rg
      ON (h3.id = rg.id)
   LEFT OUTER JOIN hierarchy h4 on (oco.id=h4.id)
   LEFT OUTER JOIN contacts_common cco on (h4.name=cco.initem)
   LEFT OUTER JOIN hierarchy h5 on (cco.id=h5.parentid and h5.name='contacts_common:webAddressGroupList' and h5.pos=0)
   LEFT OUTER JOIN webaddressgroup wag on (h5.id=wag.id)
   LEFT OUTER JOIN cinefiles_denorm.docsubjectstring dss
      ON (cast(co.objectnumber as bigint) = dss.doc_id)
   LEFT OUTER JOIN cinefiles_denorm.docnamesubjectstring dnss
      ON (cast(co.objectnumber as bigint) = dnss.doc_id)
   LEFT OUTER JOIN cinefiles_denorm.docauthoridstring daids
      ON (cast(co.objectnumber as bigint) = daids.doc_id)
   INNER JOIN collectionspace_core core on co.id=core.id
WHERE (co.objectnumber ~ '^[0-9]+$' ) and co.recordstatus='approved'
order by cast(co.objectnumber as bigint);

grant select on cinefiles_denorm.doclist_view to group reporters;
grant select on cinefiles_denorm.doclist_view to group cinereaders;