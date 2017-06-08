SELECT DISTINCT
cc.id, STRING_AGG(DISTINCT REGEXP_REPLACE(efc.item, '^.*\)''(.*)''$', '\1'),'␥') AS "objfilecode_ss"
FROM collectionobjects_common cc
JOIN collectionobjects_pahma_pahmaethnographicfilecodelist efc ON (efc.id=cc.id)
WHERE efc.item IS NOT NULL
GROUP BY cc.id