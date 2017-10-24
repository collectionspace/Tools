CREATE OR REPLACE FUNCTION findcurrentlocation(character varying) RETURNS character varying
    AS '
    SELECT 
     (CASE WHEN ma.crate IS NULL
        THEN regexp_replace(m.currentlocation, ''^.*\)''''(.*)''''$'', ''\1'')  
        ELSE concat(regexp_replace(m.currentlocation, ''^.*\)''''(.*)''''$'', ''\1''),
        '': '',regexp_replace(ma.crate, ''^.*\)''''(.*)''''$'', ''\1'')) END) AS storageLocation
FROM movements_common m
JOIN hierarchy h1 ON (h1.id=m.id)
JOIN movements_anthropology ma ON (ma.id=h1.id)
JOIN relations_common r ON (r.subjectcsid=h1.name AND r.subjectdocumenttype=''Movement'' AND r.objectdocumenttype=''CollectionObject'')
JOIN hierarchy h2 ON (h2.name=r.objectcsid)
JOIN collectionobjects_common c ON (c.id=h2.id)
JOIN misc misc ON (misc.id=c.id AND misc.lifecyclestate <> ''deleted'')
WHERE m.currentlocation IS NOT NULL
AND h2.name=$1
ORDER BY DATE(m.locationdate AT TIME ZONE ''GMT-8'') DESC,ROW_NUMBER() OVER(ORDER BY m.locationdate AT TIME ZONE ''GMT-8'')
LIMIT 1  
' LANGUAGE SQL
    IMMUTABLE
    RETURNS NULL ON NULL INPUT;
