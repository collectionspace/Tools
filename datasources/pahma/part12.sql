SELECT cc.id, scd.datedisplaydate AS "objcolldate_txt",
DATE(scd.dateearliestscalarvalue) AS "objcolldate_begin_dt", scd.dateearliestsingleera AS "objcolldate_beginera_txt",
DATE(scd.datelatestscalarvalue) AS "objcolldate_end_dt", scd.datelatestera AS "objcolldate_endera_txt"
FROM collectionobjects_common cc
JOIN hierarchy hcd ON (hcd.parentid=cc.id AND hcd.primarytype='structuredDateGroup' AND hcd.name='collectionobjects_pahma:pahmaFieldCollectionDateGroupList' AND (hcd.pos=0 or hcd.pos IS NULL))
JOIN structureddategroup scd ON (scd.id=hcd.id)
WHERE scd.datedisplaydate IS NOT NULL