SELECT
   csid.name AS csid_s,
   csid.id as id,
   REGEXP_REPLACE(co.computedcurrentlocation, '^.*\)''(.*)''$', '\1') AS storagelocation_s,
   REGEXP_REPLACE(ca.computedcrate, '^.*\)''(.*)''$', '\1') AS computedcrate_s,
   co.objectnumber AS objectumber_s,
   cp.sortableobjectnumber as sortableobjectnumber_s,
   co.numberofobjects AS "objectcount_s",
   ong.objectName AS objectname_s, 
   cp.inventorycount as count_s
FROM collectionobjects_common co
JOIN hierarchy csid ON (co.id = csid.id)
LEFT OUTER JOIN hierarchy h1 ON (co.id = h1.parentid AND h1.pos=0 AND h1.name='collectionobjects_common:objectNameList')
LEFT OUTER JOIN objectnamegroup ong ON (ong.id=h1.id)
JOIN collectionobjects_pahma cp ON (co.id=cp.id)
JOIN collectionobjects_anthropology ca ON (co.id=ca.id)
JOIN misc ms ON (co.id=ms.id AND ms.lifecyclestate <> 'deleted')
