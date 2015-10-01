SELECT
  h2.name                                                 AS "objectcsid",
  cc.objectnumber,
  h1.name                                                 AS "mediacsid",
  mc.description,
  bc.name,
  mc.creator                                                 creatorRefname,
  REGEXP_REPLACE(mc.creator, '^.*\)''(.*)''$', '\1')      AS "creator",
  mc.blobcsid,
  mc.copyrightstatement,
  mc.identificationnumber,
  mc.rightsholder                                            rightsholderRefname,
  REGEXP_REPLACE(mc.rightsholder, '^.*\)''(.*)''$', '\1') AS "rightsholder",
  mc.contributor,
  mp.approvedforweb,
  CASE WHEN (mc.description ILIKE '%catalog card%' OR mc.description ILIKE 'Index%' OR
             mc.description LIKE 'HSR datasheet%') THEN 'card'
  ELSE 'notcard' END                                      AS "imageType"

FROM media_common mc
  JOIN media_pahma mp ON (mp.id = mc.id)

  LEFT OUTER JOIN hierarchy h1 ON (h1.id = mc.id)
  INNER JOIN relations_common rc ON (h1.name = rc.objectcsid AND rc.subjectdocumenttype = 'CollectionObject')
  LEFT OUTER JOIN hierarchy h2 ON (rc.subjectcsid = h2.name)
  LEFT OUTER JOIN collectionobjects_common cc ON (h2.id = cc.id)
  LEFT OUTER JOIN collectionobjects_pahma cp ON (h2.id = cp.id)
  JOIN hierarchy h3 ON (mc.blobcsid = h3.name)
  LEFT OUTER JOIN blobs_common bc ON (h3.id = bc.id)
