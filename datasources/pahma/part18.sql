SELECT DISTINCT
  cc.id,
  STRING_AGG(ec.exhibitionnumber, '␥') AS "exhibitionnumber_ss",
  STRING_AGG(ec.exhibitiontitle, '␥')  AS "exhibitiontitle_ss"
FROM collectionobjects_common cc
  JOIN hierarchy hti ON (hti.parentid = cc.id AND hti.primarytype = 'exhibitionGroup')
  JOIN exhibitionobjectgroup eog ON (eog.id = hti.id)
WHERE ec.exhibitionnumber IS NOT NULL
GROUP BY cc.id
