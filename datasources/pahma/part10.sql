SELECT cc.id, com.item AS "objcomment_s"
FROM collectionobjects_common cc
JOIN collectionobjects_common_comments com ON (com.id=cc.id AND (com.pos=0 OR com.pos IS NULL))