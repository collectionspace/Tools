SELECT cc.id, ug.usage AS "objcontextuse_s"
FROM collectionobjects_common cc
JOIN hierarchy hu ON (hu.parentid=cc.id AND hu.primarytype='usageGroup' AND (hu.pos=0 OR hu.pos IS NULL))
JOIN usagegroup ug ON (ug.id=hu.id)
WHERE ug.usage IS NOT NULL