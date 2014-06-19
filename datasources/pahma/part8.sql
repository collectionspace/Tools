SELECT DISTINCT cc.id, STRING_AGG(DISTINCT REGEXP_REPLACE(mat.material, '^.*\)''(.*)''$', '\1')
	       ||CASE WHEN (mat.materialcomponent IS NOT NULL OR mat.materialcomponentnote IS NOT NULL) THEN ' (' ELSE '' END
	       ||CASE WHEN (mat.materialcomponent IS NOT NULL AND mat.materialcomponent <>'') THEN mat.materialcomponent ELSE '' END
	       ||CASE WHEN (mat.materialcomponent IS NOT NULL AND mat.materialcomponentnote IS NOT NULL) THEN ', ' ELSE '' END
	       ||CASE WHEN (mat.materialcomponentnote IS NOT NULL AND mat.materialcomponentnote <>'') THEN mat.materialcomponentnote ELSE '' END
	       ||CASE WHEN (mat.materialcomponent IS NOT NULL OR mat.materialcomponentnote IS NOT NULL) THEN ')' ELSE '' END, '␥') AS "objmaterials_ss"
FROM collectionobjects_common cc
JOIN hierarchy hm ON (hm.parentid=cc.id AND hm.primarytype='materialGroup')
JOIN materialgroup mat ON (mat.id=hm.id)
WHERE mat.material IS NOT NULL
GROUP BY cc.id