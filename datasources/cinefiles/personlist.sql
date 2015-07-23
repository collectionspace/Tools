-- personlist.sql, used in cinefiles_denorm
-- gets lookup table of persons, for use by Mediatrope
-- CRH 7/31/2014

-- drop table cinefiles_denorm.personlist

create table cinefiles_denorm.personlist as
select 
   cinefiles_denorm.getshortid(pc.refname) as shortid, 
   cinefiles_denorm.getdispl(pc.refname) as personname,
   cc.updatedat
from persons_common pc
join misc on misc.id=pc.id
join collectionspace_core cc on pc.id=cc.id
where misc.lifecyclestate <> 'deleted'
order by personname;

grant select on cinefiles_denorm.personlist to group reporters;
grant select on cinefiles_denorm.personlist to group cinereaders;