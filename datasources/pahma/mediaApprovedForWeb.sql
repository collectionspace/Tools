SELECT h2.name AS "objectcsid", cc.objectnumber, h1.name AS "mediacsid", mc.description, bc.name, mc.creator creatorRefname, REGEXP_REPLACE(mc.creator, '^.*\)''(.*)''$', '\1') AS "creator", 
mc.blobcsid, mc.copyrightstatement, mc.identificationnumber, mc.rightsholder rightsholderRefname, REGEXP_REPLACE(mc.rightsholder, '^.*\)''(.*)''$', '\1') AS "rightsholder",
mc.contributor, mp.approvedforweb, 'notcard' AS "imageType"

FROM media_common mc
JOIN media_pahma mp ON (mp.id = mc.id)

LEFT OUTER JOIN hierarchy h1 ON (h1.id = mc.id)
INNER JOIN relations_common rc on (h1.name = rc.objectcsid AND rc.subjectdocumenttype='CollectionObject')
LEFT OUTER JOIN hierarchy h2 on (rc.subjectcsid = h2.name)
LEFT OUTER JOIN collectionobjects_common cc on (h2.id = cc.id)
RIGHT OUTER JOIN collectionobjects_pahma_pahmaobjectstatuslist osl ON (cc.id = osl.id)
LEFT OUTER JOIN collectionobjects_pahma cp on (h2.id = cp.id)
JOIN hierarchy h3 ON (mc.blobcsid = h3.name)
LEFT OUTER JOIN blobs_common bc on (h3.id = bc.id)

WHERE mc.id NOT IN (SELECT mc.id
FROM media_common mc
WHERE mc.description LIKE 'Primary catalog card%'
OR mc.description ILIKE 'Catalog card%'
OR mc.description ILIKE 'Bulk entry catalog card%'
OR mc.description ILIKE 'Problematic catalog card%'
OR mc.description ILIKE 'Recataloged objects catalog card%'
OR mc.description ILIKE 'Revised catalog card%'
OR mc.description ILIKE 'Index%'
OR mc.description LIKE 'HSR datasheet%')
AND mp.approvedforweb = 'true'
AND h2.name NOT IN (SELECT h.name AS "objectcsid"

FROM collectionobjects_common cc
JOIN hierarchy h ON (cc.id = h.id)
JOIN collectionobjects_pahma cp on (cc.id = cp.id)
FULL OUTER JOIN collectionobjects_pahma_pahmaobjectstatuslist osl0 ON (cc.id = osl0.id AND osl0.pos=0)
FULL OUTER JOIN collectionobjects_pahma_pahmaobjectstatuslist osl1 ON (cc.id = osl1.id AND osl1.pos=1)
FULL OUTER JOIN collectionobjects_pahma_pahmaobjectstatuslist osl2 ON (cc.id = osl2.id AND osl2.pos=2)

WHERE (cp.pahmatmslegacydepartment = 'Human Remains' AND osl0.item LIKE '%culturally%')
   OR (cp.pahmatmslegacydepartment = 'Human Remains' AND osl1.item LIKE '%culturally%')
   OR (cp.pahmatmslegacydepartment = 'Human Remains' AND osl2.item LIKE '%culturally%'))
