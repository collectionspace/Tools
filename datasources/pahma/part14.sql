SELECT DISTINCT cc.id, STRING_AGG(DISTINCT REGEXP_REPLACE(fc.item, '^.*\)''(.*)''$', '\1'), '␥') AS "objcollector_ss"
FROM collectionobjects_common cc
JOIN collectionobjects_common_fieldcollectors fc ON (fc.id=cc.id)
WHERE fc.item IS NOT NULL
GROUP BY cc.id