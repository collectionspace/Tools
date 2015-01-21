-- docnamesubjectcitation table used in cinefiles denorm in
-- document citation function doc_detail_summary.sql
--
-- CRH 3/17/2014
-- 4/7/2014 using concat_personname function
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 8/3/2014

DROP TABLE IF EXISTS cinefiles_denorm.docnamesubjectcitationtmp;

CREATE TABLE cinefiles_denorm.docnamesubjectcitationtmp AS
   SELECT
   --   h1.name objectCSID,
      cast(co.objectnumber AS bigint) doc_id,
      CASE
         WHEN ccn.item like '%orgauthorities%'
           THEN trim(trailing ', ' FROM replace(replace(concat_ws(', ', cinefiles_denorm.getdispl(ccn.item), ocf.foundingcity, ocf.foundingcity, cinefiles_denorm.getdispl(oc.foundingplace)), ', , , ', ', '), ', , ', ', '))
         ELSE
           cinefiles_denorm.concat_personname(cinefiles_denorm.getshortid(ccn.item))
      END AS subjcitation
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
      LEFT OUTER JOIN organizations_common oc
         ON (ccn.item=oc.refname)
      LEFT OUTER JOIN organizations_cinefiles ocf
         ON (oc.id=ocf.id)
      LEFT OUTER JOIN persons_common pc
         ON (ccn.item=pc.refname)
      LEFT OUTER JOIN persons_cinefiles pcf
         ON (pc.id=pcf.id)
   WHERE (co.objectnumber ~ '^[0-9]+$')
     AND ccn.item IS NOT NULL AND ccn.item <> ''
   ORDER BY cast(co.objectnumber AS bigint);

GRANT SELECT ON cinefiles_denorm.docnamesubjectcitationtmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.docnamesubjectcitationtmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.docnamesubjectcitation;
SELECT COUNT(1) FROM cinefiles_denorm.docnamesubjectcitationtmp;

