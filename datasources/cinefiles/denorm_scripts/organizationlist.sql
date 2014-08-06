-- organizationlist.sql, used in cinefiles_denorm
-- gets lookup table of persons, for use by Mediatrope
--
-- CRH 7/31/2014
--
-- organizationlist.sql, used in cinefiles_denorm
-- gets lookup table of persons, for use by Mediatrope
--
-- CRH 7/31/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified, GLJ 8/2/2014

DROP TABLE IF EXISTS cinefiles_denorm.organizationlisttmp;

CREATE TABLE cinefiles_denorm.organizationlisttmp AS
   SELECT
      cinefiles_denorm.getshortid(oc.refname) AS shortid,
      cinefiles_denorm.getdispl(oc.refname) AS orgname,
      cc.updatedat
   FROM organizations_common oc
      INNER JOIN misc
         ON misc.id=oc.id
      INNER JOIN collectionspace_core cc
         ON oc.id=cc.id
   WHERE misc.lifecyclestate <> 'deleted'
   ORDER BY orgname;

GRANT SELECT ON cinefiles_denorm.organizationlisttmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.organizationlisttmp TO GROUP cinereaders;

SELECT COUNT(1) FROM cinefiles_denorm.organizationlist;
SELECT COUNT(1) FROM cinefiles_denorm.organizationlisttmp;

