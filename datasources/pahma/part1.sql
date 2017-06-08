SELECT cc.id, ong.objectName AS "objname_s"
FROM collectionobjects_common cc
JOIN hierarchy hn ON (cc.id=hn.parentid AND hn.name='collectionobjects_common:objectNameList' AND (hn.pos=0 OR hn.pos IS NULL))
JOIN objectnamegroup ong ON (ong.id=hn.id)
WHERE ong.objectName IS NOT NULL