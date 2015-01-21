-- personlist.sql, used in cinefiles_denorm
-- gets lookup table of persons, for use by Mediatrope
--
-- CRH 7/31/2014
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 8/3/2014

DROP TABLE IF EXISTS cinefiles_denorm.personlisttmp;

CREATE TABLE cinefiles_denorm.personlisttmp AS
   SELECT
      cinefiles_denorm.getshortid(pc.refname) AS shortid, 
      cinefiles_denorm.getdispl(pc.refname) AS personname,
      cc.updatedat
   FROM persons_common pc
      INNER JOIN misc
         ON misc.id=pc.id
      INNER JOIN collectionspace_core cc
         ON pc.id=cc.id
   WHERE misc.lifecyclestate <> 'deleted'
   ORDER BY personname;

GRANT SELECT ON cinefiles_denorm.personlisttmp TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.personlisttmp TO GROUP cinereaders;

SELECT COUNT(1) from cinefiles_denorm.personlist;
SELECT COUNT(1) from cinefiles_denorm.personlisttmp;

