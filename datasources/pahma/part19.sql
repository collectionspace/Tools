SELECT
  cc.id,
  regexp_replace(cc.computedcurrentlocation, '^.*\)''(.*)''$', '\1') AS currentlocation_s,
  regexp_replace(ca.computedcrate, '^.*\)''(.*)''$', '\1')           AS computedcrate_s,
  conh.donor                                                         AS donor_s,
  'condition'                                                        AS condition_s

FROM collectionobjects_common cc
  JOIN hierarchy h1 ON (h1.id = cc.id)
  JOIN collectionobjects_pahma cp ON (cc.id = cp.id)
  JOIN collectionobjects_anthropology ca ON (cc.id = ca.id)
  FULL OUTER JOIN collectionobjects_naturalhistory conh ON (cc.id = conh.id)
  JOIN misc ON (cc.id = misc.id AND misc.lifecyclestate <> 'deleted')
