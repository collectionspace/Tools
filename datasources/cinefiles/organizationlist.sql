-- organizationlist.sql, used in cinefiles_denorm
-- gets lookup table of persons, for use by Mediatrope
-- CRH 7/31/2014

-- drop table cinefiles_denorm.organizationlist

-- organizationlist.sql, used in cinefiles_denorm
-- gets lookup table of persons, for use by Mediatrope
-- CRH 7/31/2014

-- drop table cinefiles_denorm.organizationlist

create table cinefiles_denorm.organizationlist as
select 
   cinefiles_denorm.getshortid(oc.refname) as shortid, 
   cinefiles_denorm.getdispl(oc.refname) as orgname,
   cc.updatedat
from organizations_common oc
join misc on misc.id=oc.id
join collectionspace_core cc on oc.id=cc.id
where misc.lifecyclestate <> 'deleted'
order by orgname;

grant select on cinefiles_denorm.organizationlist to group reporters;
grant select on cinefiles_denorm.organizationlist to group cinereaders;