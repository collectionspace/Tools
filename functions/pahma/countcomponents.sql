CREATE OR REPLACE FUNCTION countcomponents(character varying) RETURNS bigint AS
$$
SELECT
count(*)
FROM collectionobjects_common c1 
join HIERARCHY h1 on (h1.id=c1.id)
join relations_common r on (r.subjectcsid = h1.NAME AND r.subjectdocumenttype = 'CollectionObject'
     AND r.objectdocumenttype = 'CollectionObject')
join HIERARCHY h2 on (r.objectcsid=h2.name) 
join collectionobjects_common c2 on (h2.id=c2.id)
join collectionobjects_pahma cp on (cp.id=c1.id)
join collectionobjects_pahma cp2 on (cp2.id=c2.id)
WHERE cp.iscomponent='no' and cp2.iscomponent='yes'
  and h1.name=$1
$$ 
LANGUAGE SQL
    IMMUTABLE
    RETURNS NULL ON NULL INPUT;
