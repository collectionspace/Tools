SELECT cc.id, STRING_AGG(DISTINCT REGEXP_REPLACE(opp.objectproductionplace, '^.*\)''(.*)''$', '\1'),'␥') AS "objpp_ss"
FROM collectionobjects_common cc
JOIN hierarchy h ON (cc.id=h.parentid AND h.primarytype='objectProductionPlaceGroup')
JOIN objectproductionplacegroup opp ON (h.id=opp.id)
GROUP BY cc.id
