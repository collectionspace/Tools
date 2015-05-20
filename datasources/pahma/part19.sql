SELECT
  cc.id,
  regexp_replace(cc.computedcurrentlocation, '^.*\)''(.*)''$', '\1') AS currentlocation_s,
  conh.donor                                                         AS donor_s,
  'condition'                                                        AS condition_s

FROM collectionobjects_common cc
  JOIN hierarchy h1 ON (h1.id = cc.id)
  JOIN collectionobjects_pahma cp ON (cp.id = cc.id)
  JOIN collectionobjects_naturalhistory conh ON (cc.id = conh.id)
  JOIN misc ON (cc.id = misc.id AND misc.lifecyclestate <> 'deleted')