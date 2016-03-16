select lt.termdisplayname, lt.termname, lt.termstatus, l.shortidentifier,               
  l.refname from loctermgroup lt                                                                
  inner join hierarchy h1 on (lt.id=h1.id)
  left outer join locations_common l on (h1.parentid=l.id) 
  where l.inauthority='d65c614a-e70e-441b-8855'                                                 
  order by l.shortidentifier;
