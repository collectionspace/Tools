SELECT
  cc.id,
  ec.exhibitionnumber AS exhibitionnumber_s,
  ec.title            AS exhibitiontitle_s

FROM exhibitions_common ec

  JOIN hierarchy h1 ON (ec.id = h1.id)
  JOIN relations_common rc ON (h1.name = rc.objectcsid)
  JOIN hierarchy h2 ON (rc.subjectcsid = h2.name)
  JOIN collectionobjects_common cc ON (h2.id = cc.id)

  JOIN hierarchy h3 ON (h3.parentid = ec.id)
  JOIN exhibitionobjectgroup eog ON (eog.id = h3.id)
