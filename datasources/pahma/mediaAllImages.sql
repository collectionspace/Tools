SELECT h2.name AS "objectcsid", cc.objectnumber, h1.name AS "mediacsid", mc.description, bc.name, mc.creator creatorRefname, REGEXP_REPLACE(mc.creator, '^.*\)''(.*)''$', '\1') AS "creator", 
mc.blobcsid, mc.copyrightstatement, mc.identificationnumber, mc.rightsholder rightsholderRefname, REGEXP_REPLACE(mc.rightsholder, '^.*\)''(.*)''$', '\1') AS "rightsholder",
mc.contributor, mp.approvedforweb, 
case when (mc.description ILIKE '%catalog card%' OR mc.description ILIKE 'Index%') then 'card' ELSE 'notcard' END AS "imageType"

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

