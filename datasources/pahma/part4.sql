SELECT cc.id, inv.item AS "objinventory_s"
FROM collectionobjects_common cc
JOIN collectionobjects_anthropology_nagprainventorynamelist inv ON (inv.id=cc.id AND (inv.pos=0 OR inv.pos IS NULL))
WHERE inv.item IS NOT NULL