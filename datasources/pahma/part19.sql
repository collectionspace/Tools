SELECT cc.id, STRING_AGG(REGEXP_REPLACE(opp.objectproductionperson, '^.*\)''(.*)''$', '\1'), '␥') AS "objmaker_ss"
FROM collectionobjects_common cc
JOIN hierarchy hm ON (cc.id=hm.parentid AND hm.primarytype='objectProductionPersonGroup')
JOIN objectproductionpersongroup opp ON (opp.id=hm.id)
JOIN misc m ON (cc.id=m.id AND m.lifecyclestate<>'deleted')
WHERE opp.objectproductionperson IS NOT NULL
GROUP BY cc.id
