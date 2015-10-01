SELECT h2.name AS "objectcsid", cc.objectnumber, h1.name AS "mediacsid", mc.description, bc.name, mc.creator creatorRefname, REGEXP_REPLACE(mc.creator, '^.*\)''(.*)''$', '\1') AS "creator", 
mc.blobcsid, mc.copyrightstatement, mc.identificationnumber, mc.rightsholder rightsholderRefname, REGEXP_REPLACE(mc.rightsholder, '^.*\)''(.*)''$', '\1') AS "rightsholder",
mc.contributor, mp.approvedforweb, 'card' AS "imageType"

FROM media_common mc
JOIN media_pahma mp ON (mp.id = mc.id)

LEFT OUTER JOIN hierarchy h1 ON (h1.id = mc.id)
INNER JOIN relations_common rc on (h1.name = rc.objectcsid AND rc.subjectdocumenttype='CollectionObject')
LEFT OUTER JOIN hierarchy h2 on (rc.subjectcsid = h2.name)
LEFT OUTER JOIN collectionobjects_common cc on (h2.id = cc.id)
LEFT OUTER JOIN collectionobjects_pahma cp on (h2.id = cp.id)
JOIN hierarchy h3 ON (mc.blobcsid = h3.name)
LEFT OUTER JOIN blobs_common bc on (h3.id = bc.id)

WHERE mc.id IN (SELECT mc.id
FROM media_common mc
WHERE mc.description LIKE 'Primary catalog card%'
OR mc.description ILIKE 'Catalog card%'
OR mc.description ILIKE 'Bulk entry catalog card%'
OR mc.description ILIKE 'Problematic catalog card%'
OR mc.description ILIKE 'Recataloged objects catalog card%'
OR mc.description ILIKE 'Revised catalog card%'
OR mc.description ILIKE 'Index%'
OR mc.description LIKE 'HSR datasheet%')
