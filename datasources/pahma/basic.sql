SELECT cc.id, h1.name  AS "objcsid", cp.sortableobjectnumber AS "objsortnum",
cc.objectnumber AS "objmusno", cp.pahmatmslegacydepartment AS "objdept",
cc.collection AS "objtype", cc.numberofobjects AS "objcount", cp.inventorycount AS "objcountnote",
cp.portfolioseries AS "objkeelingser", cp.pahmafieldlocverbatim AS "objfcpverbatim"
FROM collectionobjects_common cc
JOIN hierarchy h1 ON (h1.id=cc.id)
JOIN collectionobjects_pahma cp ON (cp.id=cc.id)
JOIN misc ON (cc.id=misc.id and misc.lifecyclestate <>'deleted')