SELECT
  cc.id,
  regexp_replace(cc.computedcurrentlocation, '^.*\)''(.*)''$', '\1')         AS currentlocation_s,
  regexp_replace(ca.computedcrate, '^.*\)''(.*)''$', '\1')                   AS computedcrate_s,
  STRING_AGG(DISTINCT REGEXP_REPLACE(adg.donor, '^.*\)''(.*)''$', '\1'),'␥') AS "donor_ss",
  'condition'                                                                AS condition_s

FROM collectionobjects_common cc
  JOIN hierarchy h1 ON (h1.id=cc.id)
  JOIN collectionobjects_anthropology ca ON (cc.id=ca.id)
  LEFT OUTER JOIN relations_common rc ON (h1.name=rc.subjectcsid AND rc.objectdocumenttype='Acquisition')
  LEFT OUTER JOIN hierarchy h2 ON (rc.objectcsid=h2.name)
  LEFT OUTER JOIN acquisitions_common ac ON (h2.id=ac.id)
  LEFT OUTER JOIN hierarchy h3 ON (ac.id=h3.parentid AND h3.name='acquisitions_pahma:acquisitionDonorGroupList')
  LEFT OUTER JOIN acquisitiondonorgroup adg ON (adg.id=h3.id)
  FULL OUTER JOIN collectionobjects_naturalhistory conh ON (cc.id=conh.id)
  JOIN misc ON (cc.id = misc.id AND misc.lifecyclestate <> 'deleted')
  
 GROUP BY cc.id, cc.computedcurrentlocation, ca.computedcrate