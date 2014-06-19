SELECT DISTINCT cc.id, spd.datedisplaydate AS "objproddate_txt",
DATE(spd.dateearliestscalarvalue) AS "objproddate_begin_dt", spd.dateearliestsingleera AS "objproddate_beginera_txt",
DATE(spd.datelatestscalarvalue) AS "objproddate_end_dt", spd.datelatestera AS "objproddate_endera_txt"
FROM collectionobjects_common cc
JOIN hierarchy hpd ON (hpd.parentid=cc.id AND hpd.primarytype='structuredDateGroup' AND hpd.name='collectionobjects_common:objectProductionDateGroupList' AND (hpd.pos=0 or hpd.pos IS NULL))
JOIN structureddategroup spd ON (spd.id=hpd.id)
WHERE spd.datedisplaydate IS NOT NULL