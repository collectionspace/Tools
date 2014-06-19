SELECT cc.id, scd.datedisplaydate AS "objcolldate_txt"
FROM collectionobjects_common cc
JOIN hierarchy hcd ON (hcd.parentid=cc.id AND hcd.primarytype='structuredDateGroup' AND hcd.name='collectionobjects_pahma:pahmaFieldCollectionDateGroupList' AND (hcd.pos=0 or hcd.pos IS NULL))
JOIN structureddategroup scd ON (scd.id=hcd.id)
WHERE scd.datedisplaydate IS NOT NULL