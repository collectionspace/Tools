-- doclist_view, used in CineFiles denorm primary source for searching documents
--
-- CRH 7/31/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified, GLJ 8/2/2014

DROP TABLE IF EXISTS cinefiles_denorm.doclist_viewtmp;

CREATE TABLE cinefiles_denorm.doclist_viewtmp AS
   SELECT
      -- h1.name objectCSID,
      cast(co.objectnumber AS bigint) doc_id,
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
     CASE WHEN (cc.accesscode IS NULL OR cc.accesscode = '')
      THEN
      CASE WHEN ocf.accesscode = 'PFA Staff Only' THEN 0
         WHEN ocf.accesscode = 'In House Only' THEN 1
         WHEN ocf.accesscode = 'Campus (UCB)' THEN 2
         WHEN ocf.accesscode = 'Education (.edu)' THEN 3
         WHEN ocf.accesscode = 'World' THEN 4
         WHEN (cc.source IS NULL OR cc.source='') THEN 4
         ELSE NULL
      END
      ELSE
      CASE WHEN cc.accesscode = 'PFA Staff Only' THEN 0
         WHEN cc.accesscode = 'In House Only' THEN 1
         WHEN cc.accesscode = 'Campus (UCB)' THEN 2
         WHEN cc.accesscode = 'Education (.edu)' THEN 3
         WHEN cc.accesscode = 'World' THEN 4
         ELSE NULL
      END
     END AS code,
      cc.hascastcr AS cast_cr,
      cc.hastechcr AS tech_cr,
      cc.hasboxinfo AS bx_info,
      cc.hasfilmog AS filmog,
      cc.hasdistco AS dist_co,
      cc.hasprodco AS prod_co,
      cc.hascostinfo AS costinfo,
      cc.hasillust AS illust,
      cc.hasbiblio AS biblio,
      rg.referencenote docurl,
      sdg.dateearliestscalarvalue pubdatescalar,
      sdg.datelatestscalarvalue latepubdatescalar,
      wag.webaddress srcUrl,
      dss.docsubjects docsubject,
      dnss.docnamesubjects docnamesubject,
      core.updatedat
   FROM
      hierarchy h1
      INNER JOIN collectionobjects_common co
         ON (h1.id = co.id
            AND h1.primarytype = 'CollectionObjectTenant50')
      INNER JOIN misc m
         ON (co.id = m.id
            AND m.lifecyclestate <> 'deleted')
      INNER JOIN collectionobjects_cinefiles cc
         ON (co.id = cc.id)
      LEFT OUTER JOIN cinefiles_denorm.doclanguagestring dls
         ON (cast(co.objectnumber AS bigint) = dls.doc_id)
      LEFT OUTER JOIN cinefiles_denorm.docauthorstring das
         ON (cast(co.objectnumber AS bigint) = das.doc_id)
      LEFT OUTER JOIN hierarchy h2
         ON (h2.parentid = co.id
            AND h2.name='collectionobjects_common:objectProductionDateGroupList'
            AND h2.pos=0)
      LEFT OUTER JOIN structuredDateGroup sdg
         ON (h2.id = sdg.id)
      LEFT OUTER JOIN organizations_common oco
         ON (cc.source=oco.refname)
      LEFT OUTER JOIN organizations_cinefiles ocf
         ON (oco.id=ocf.id)
      LEFT OUTER JOIN hierarchy h3
         ON (h3.parentid = co.id
            AND h3.primarytype = 'referenceGroup'
            AND h3.pos=0)
      LEFT OUTER JOIN referencegroup rg
         ON (h3.id = rg.id)
      LEFT OUTER JOIN hierarchy h4
         ON (oco.id=h4.id)
      LEFT OUTER JOIN contacts_common cco
         ON (h4.name=cco.initem)
      LEFT OUTER JOIN hierarchy h5
         ON (cco.id=h5.parentid
            AND h5.name='contacts_common:webAddressGroupList'
            AND h5.pos=0)
      LEFT OUTER JOIN webaddressgroup wag
         ON (h5.id=wag.id)
      LEFT OUTER JOIN cinefiles_denorm.docsubjectstring dss
         ON (cast(co.objectnumber AS bigint) = dss.doc_id)
      LEFT OUTER JOIN cinefiles_denorm.docnamesubjectstring dnss
         ON (cast(co.objectnumber AS bigint) = dnss.doc_id)
      LEFT OUTER JOIN cinefiles_denorm.docauthoridstring daids
         ON (cast(co.objectnumber AS bigint) = daids.doc_id)
      INNER JOIN collectionspace_core core
         ON co.id=core.id
   WHERE (co.objectnumber ~ '^[0-9]+$')
     AND co.recordstatus='approved'
   ORDER BY cast(co.objectnumber AS bigint);

GRANT SELECT ON cinefiles_denorm.doclist_viewtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.doclist_viewtmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.doclist_view;
SELECT COUNT(1) FROM cinefiles_denorm.doclist_viewtmp;

