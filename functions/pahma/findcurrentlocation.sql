CREATE OR REPLACE FUNCTION findcurrentlocation(character varying) RETURNS character varying
    AS '
    select 
     (case when ma.crate is Null then regexp_replace(m.currentlocation, ''^.*\)''''(.*)''''$'', ''\1'')  
     else concat(regexp_replace(m.currentlocation, ''^.*\)''''(.*)''''$'', ''\1''),
     '': '',regexp_replace(ma.crate, ''^.*\)''''(.*)''''$'', ''\1'')) end) as storageLocation
from movements_common m,
movements_anthropology ma,
hierarchy h1, 
relations_common r, 
hierarchy h2,
collectionobjects_common c,
misc misc
where m.id=h1.id
and ma.id = h1.id
and r.subjectcsid=h1.name 
and r.subjectdocumenttype=''Movement'' 
and r.objectdocumenttype=''CollectionObject''
and r.objectcsid=h2.name 
and h2.id=c.id
and misc.id = c.id
and misc.lifecyclestate <> ''deleted''
and m.currentlocation is not null
and h2.name=$1
order by m.locationdate desc,row_number() over(order by locationdate)
limit 1    
' LANGUAGE SQL
    IMMUTABLE
    RETURNS NULL ON NULL INPUT;