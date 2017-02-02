select pt.termname, pt.termdisplayname, p.refname 
from persontermgroup pt 
inner join hierarchy h1 on (pt.id=h1.id) 
left outer join persons_common p on (h1.parentid=p.id);
