SELECT cc.id, tg.title ||CASE WHEN (tg.titletype IS NOT NULL AND tg.titletype <>'') THEN ' ('|| tg.titletype || ')' ELSE '' END AS "objtitle_s"
FROM collectionobjects_common cc
JOIN hierarchy ht ON (ht.parentid=cc.id AND ht.primarytype='titleGroup' AND (ht.pos=0 OR ht.pos IS NULL))
JOIN titlegroup tg ON (tg.id=ht.id)
WHERE tg.title IS NOT NULL