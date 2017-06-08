SELECT
  cc.id,
  h1.name                     AS "csid_s",
  cp.sortableobjectnumber     AS "objsortnum_s",
  cc.objectnumber             AS "objmusno_s",
  cp.pahmatmslegacydepartment AS "objdept_s",
  cc.collection               AS "objtype_s",
  cc.numberofobjects          AS "objcount_s",
  cp.inventorycount           AS "objcountnote_s",
  cp.portfolioseries          AS "objkeelingser_s",
  cp.pahmafieldlocverbatim    AS "objfcpverbatim_s"
FROM collectionobjects_common cc
  JOIN hierarchy h1 ON (h1.id = cc.id)
  JOIN collectionobjects_pahma cp ON (cp.id = cc.id)
  JOIN misc ON (cc.id = misc.id AND misc.lifecyclestate <> 'deleted')
  LEFT OUTER JOIN collectionobjects_pahma_pahmaobjectstatuslist osl ON (cc.id = osl.id)
WHERE osl.item IN ('accessioned', 'deaccessioned', 'number not used', 'recataloged', 'not received')
