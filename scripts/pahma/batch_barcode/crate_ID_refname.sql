select lt.termdisplayname, lt.termname, lt.termstatus, l.shortidentifier,
l.refname from loctermgroup lt
inner join hierarchy h1 on (lt.id=h1.id)
left outer join locations_common l on (h1.parentid=l.id)
where l.inauthority='e8069316-30bf-4cb9-b41d'
order by l.shortidentifier;
