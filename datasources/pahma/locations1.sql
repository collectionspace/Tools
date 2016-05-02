SELECT
   h2.name as csid_s,
   h1.name as id,
   REGEXP_REPLACE(mc.currentlocation, '^.*\)''(.*)''$', '\1') AS location_s,
   REGEXP_REPLACE(ma.crate, '^.*\)''(.*)''$', '\1') AS crate_s,
   DATE(mc.locationdate)||'T19:00:00Z' AS "locationdate_dt"
FROM relations_common rc
JOIN hierarchy h1 ON (h1.name = rc.objectcsid)
JOIN movements_common mc ON (mc.id = h1.id)
JOIN hierarchy h2 ON (h2.name = rc.subjectcsid)
JOIN collectionobjects_common cc ON (cc.id = h2.id)
JOIN movements_anthropology ma ON (ma.id=mc.id)
JOIN misc ms ON (mc.id=ms.id AND ms.lifecyclestate <> 'deleted')
