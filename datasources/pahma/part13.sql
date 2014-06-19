SELECT DISTINCT cc.id, spd.datedisplaydate AS "objproddate"
FROM collectionobjects_common cc
JOIN hierarchy hpd ON (hpd.parentid=cc.id AND hpd.primarytype='structuredDateGroup' AND hpd.name='collectionobjects_common:objectProductionDateGroupList' AND (hpd.pos=0 or hpd.pos IS NULL))
JOIN structureddategroup spd ON (spd.id=hpd.id)
WHERE spd.datedisplaydate IS NOT NULL