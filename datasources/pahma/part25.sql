SELECT DISTINCT
  cc.id,
  STRING_AGG(DISTINCT REGEXP_REPLACE(adg.donor, '^.*\)''(.*)''$', '\1'),'␥') AS donor_ss
FROM collectionobjects_common cc
  JOIN hierarchy h1 ON (h1.id = cc.id)
  JOIN relations_common rca ON (h1.name = rca.subjectcsid AND rca.objectdocumenttype = 'Acquisition')
  JOIN hierarchy hac ON (hac.name = rca.objectcsid AND (hac.pos = 0 OR hac.pos IS NULL))
  JOIN acquisitions_common ac ON (hac.id = ac.id)
  LEFT OUTER JOIN hierarchy h2 ON (ac.id = h2.parentid AND h2.name = 'acquisitions_pahma:acquisitionDonorGroupList')
  LEFT OUTER JOIN acquisitiondonorgroup adg ON (adg.id = h2.id)
  JOIN misc ON (cc.id = misc.id AND misc.lifecyclestate <> 'deleted')
GROUP BY cc.id
