SELECT
  cc.id,
  STRING_AGG(DISTINCT gc.title, '␥') AS "grouptitle_ss"
FROM collectionobjects_common cc

  JOIN hierarchy h1 ON (cc.id = h1.id)
  JOIN relations_common rc ON (h1.name = rc.subjectcsid AND rc.objectdocumenttype = 'Group')
  JOIN hierarchy h2 ON (rc.objectcsid = h2.name)
  LEFT OUTER JOIN groups_common gc ON (h2.id = gc.id)

GROUP BY cc.id
