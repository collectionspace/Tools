SELECT
  cc.id,
  regexp_replace(cc.computedcurrentlocation, '^.*\)''(.*)''$', '\1')         AS currentlocation_s,
  regexp_replace(ca.computedcrate, '^.*\)''(.*)''$', '\1')                   AS computedcrate_s,
  'condition'                                                                AS condition_s

FROM collectionobjects_common cc
  JOIN hierarchy h1 ON (h1.id=cc.id)
  JOIN collectionobjects_anthropology ca ON (cc.id=ca.id)
  JOIN misc ON (cc.id = misc.id AND misc.lifecyclestate <> 'deleted')
  
 GROUP BY cc.id, cc.computedcurrentlocation, ca.computedcrate
