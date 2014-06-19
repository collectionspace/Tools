SELECT DISTINCT cc.id, STRING_AGG(DISTINCT REGEXP_REPLACE(apg.assocpeople, '^.*\)''(.*)''$', '\1'),'␥') AS "objassoccult_ss", STRING_AGG(DISTINCT utils.culture_hierarchy.csid_hierarchy, '␥') AS "objculturetree_ss"
FROM collectionobjects_common cc
JOIN hierarchy hc ON (hc.parentid=cc.id AND hc.primarytype='assocPeopleGroup')
JOIN assocpeoplegroup apg ON (apg.id=hc.id)
JOIN concepts_common cnc ON (cnc.refname=apg.assocpeople)
JOIN hierarchy ccsid ON (cnc.id=ccsid.id)
LEFT OUTER JOIN utils.culture_hierarchy ON (ccsid.name= utils.culture_hierarchy.culturecsid)
GROUP BY cc.id