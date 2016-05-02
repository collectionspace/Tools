SELECT
  h2.name                                                 AS objectcsid,
  cc.objectnumber,
  h1.name                                                 AS mediacsid,
  mc.description,
  bc.name,
  mc.creator                                                 creatorRefname,
  REGEXP_REPLACE(mc.creator, '^.*\)''(.*)''$', '\1')      AS creator,
  mc.blobcsid,
  mc.copyrightstatement,
  mc.identificationnumber,
  mc.rightsholder                                            rightsholderRefname,
  REGEXP_REPLACE(mc.rightsholder, '^.*\)''(.*)''$', '\1') AS rightsholder,
  mc.contributor,
  mp.approvedforweb,
  cp.pahmatmslegacydepartment                             AS pahmatmslegacydepartment,
  osl0.item                                               AS objectstatus,
  mp.primarydisplay                                       AS primarydisplay

FROM media_common mc
  JOIN media_pahma mp ON (mp.id = mc.id)

  JOIN misc ON (mc.id = misc.id AND misc.lifecyclestate <> 'deleted')
  LEFT OUTER JOIN hierarchy h1 ON (h1.id = mc.id)
  INNER JOIN relations_common rc ON (h1.name = rc.objectcsid AND rc.subjectdocumenttype = 'CollectionObject')
  LEFT OUTER JOIN hierarchy h2 ON (rc.subjectcsid = h2.name)
  LEFT OUTER JOIN collectionobjects_common cc ON (h2.id = cc.id)
  JOIN collectionobjects_pahma cp ON (cc.id = cp.id)
  JOIN hierarchy h3 ON (mc.blobcsid = h3.name)
  LEFT OUTER JOIN blobs_common bc ON (h3.id = bc.id)
  FULL OUTER JOIN collectionobjects_pahma_pahmaobjectstatuslist osl0 ON (cc.id = osl0.id AND osl0.pos = 0)

